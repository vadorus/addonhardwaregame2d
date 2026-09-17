#!/usr/bin/env node

import { spawn } from "node:child_process";
import { createWriteStream } from "node:fs";
import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import OpenAI from "openai";

const DEFAULT_MODEL = "gpt-6-astra";
const DEFAULT_TIMEOUT_MS = 20 * 60 * 1000;
const CONNECTION_TIMEOUT_MS = 2 * 60 * 1000;

function requiredEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`La variable ${name} est absente.`);
  return value;
}

function deferred() {
  let resolvePromise;
  let rejectPromise;
  let settled = false;
  const promise = new Promise((resolve, reject) => {
    resolvePromise = resolve;
    rejectPromise = reject;
  });
  return {
    promise,
    resolve(value) {
      if (!settled) {
        settled = true;
        resolvePromise(value);
      }
    },
    reject(error) {
      if (!settled) {
        settled = true;
        rejectPromise(error);
      }
    },
  };
}

function withTimeout(promise, timeoutMs, message) {
  let timeout;
  const deadline = new Promise((_, reject) => {
    timeout = setTimeout(() => reject(new Error(message)), timeoutMs);
  });
  return Promise.race([promise, deadline]).finally(() => clearTimeout(timeout));
}

function redact(value) {
  return String(value)
    .replace(/sk-[A-Za-z0-9_-]{12,}/g, "[SECRET_REDACTED]")
    .replace(/Bearer\s+[A-Za-z0-9._-]+/gi, "Bearer [SECRET_REDACTED]");
}

function eventError(event) {
  return (
    event?.error?.message ??
    event?.turn?.error?.message ??
    event?.message ??
    event?.type ??
    "Erreur Agents API sans détail"
  );
}

async function removeContainer(name, dockerEnv) {
  await new Promise((resolve) => {
    const cleanup = spawn("docker", ["rm", "--force", name], {
      env: dockerEnv,
      stdio: "ignore",
    });
    cleanup.once("error", () => resolve());
    cleanup.once("exit", () => resolve());
  });
}

async function main() {
  const apiKey = requiredEnv("OPENAI_API_KEY");
  const executorKey = requiredEnv("OPENAI_EXECUTOR_API_KEY");
  const task = requiredEnv("AGENT_TASK");
  if (task.length < 12 || task.length > 4000) {
    throw new Error("La tâche doit contenir entre 12 et 4 000 caractères.");
  }

  const model = (process.env.AGENT_MODEL || DEFAULT_MODEL).trim();
  if (!/^[A-Za-z0-9._-]{1,80}$/.test(model)) {
    throw new Error("Le nom du modèle configuré est invalide.");
  }

  const workspace = path.resolve(process.env.GITHUB_WORKSPACE || process.cwd());
  const godotBinary = path.resolve(requiredEnv("GODOT_BIN"));
  const executorImage = process.env.AGENT_EXECUTOR_IMAGE || "tech-empire-agent:local";
  const outputDirectory = path.join(workspace, ".agent-output");
  const eventsPath = path.join(outputDirectory, "events.jsonl");
  const executorLogPath = path.join(outputDirectory, "executor.log");
  const reportPath = path.join(outputDirectory, "report.md");
  await fs.mkdir(outputDirectory, { recursive: true });
  await fs.writeFile(eventsPath, "", "utf8");

  const client = new OpenAI({ apiKey });
  const session = await client.beta.agents.sessions.create({
    agent: {
      model,
      instructions: [
        "Tu es l'agent de maintenance de Tech Empire, un jeu Godot 4.7.2.",
        "Lis AGENTS.md puis les documents pertinents avant de modifier le projet.",
        "Reste strictement dans la branche CPU actuelle.",
        "N'utilise pas le réseau, ne manipule aucun secret et ne lance aucune commande Git distante.",
        "Ne modifie jamais .github, tools/agents, AGENTS.md, .gitignore ou .gitattributes.",
        "Implémente uniquement la tâche demandée, ajoute des tests déterministes et exécute les contrôles Godot.",
        "Ne fais ni commit ni push. Termine par un rapport factuel dans .agent-output/report.md.",
      ].join(" "),
    },
    environment: {
      type: "self_hosted",
      workspace_directory: "/workspace",
    },
  });

  const environmentId = session?.environment?.id;
  const remoteUrl = session?.environment?.remote_url;
  if (!session?.id || !environmentId || !remoteUrl) {
    throw new Error("La session Agents API n'a pas fourni d'environnement exécutable.");
  }

  await fs.writeFile(
    path.join(outputDirectory, "session.json"),
    JSON.stringify(
      {
        session_id: session.id,
        environment_id: environmentId,
        model,
        started_at: new Date().toISOString(),
      },
      null,
      2,
    ),
    "utf8",
  );

  const containerName = `tech-empire-agent-${session.id}`
    .toLowerCase()
    .replace(/[^a-z0-9_.-]/g, "-")
    .slice(0, 63);
  const dockerEnv = {
    PATH: process.env.PATH || "/usr/local/bin:/usr/bin:/bin",
    HOME: process.env.HOME || "/tmp",
    CODEX_API_KEY: executorKey,
  };
  for (const name of ["DOCKER_HOST", "DOCKER_CONFIG", "XDG_RUNTIME_DIR"]) {
    if (process.env[name]) dockerEnv[name] = process.env[name];
  }

  const connected = deferred();
  const completed = deferred();
  let executor;
  let events;
  let turnFinished = false;
  let expectedStreamClose = false;
  const executorLog = createWriteStream(executorLogPath, { flags: "a" });

  try {
    events = await client.beta.agents.sessions.events.stream(session.id);
    const eventPump = (async () => {
      try {
        for await (const event of events) {
          await fs.appendFile(eventsPath, `${redact(JSON.stringify(event))}\n`, "utf8");
          switch (event.type) {
            case "agent.session.environment.connected":
              connected.resolve();
              break;
            case "error":
            case "agent.session.failed":
            case "agent.session.environment.failed": {
              const error = new Error(redact(eventError(event)));
              connected.reject(error);
              completed.reject(error);
              break;
            }
            case "agent.session.turn.failed":
            case "agent.session.turn.cancelled":
              if (event?.turn?.subagent_id == null) {
                completed.reject(new Error(redact(eventError(event))));
              }
              break;
            case "agent.session.turn.completed":
              if (event?.turn?.subagent_id == null) completed.resolve();
              break;
            default:
              break;
          }
        }
        if (!turnFinished && !expectedStreamClose) {
          completed.reject(new Error("Le flux Agents API s'est fermé avant la fin du travail."));
        }
      } catch (error) {
        if (!expectedStreamClose) {
          connected.reject(error);
          completed.reject(error);
        }
      }
    })();

    const dockerArguments = [
      "run",
      "--rm",
      "--init",
      "--name",
      containerName,
      "--read-only",
      "--cap-drop=ALL",
      "--security-opt=no-new-privileges:true",
      "--pids-limit=512",
      "--memory=4g",
      "--cpus=2",
      "--env",
      "CODEX_API_KEY",
      "--env",
      "HOME=/tmp",
      "--env",
      "CI=true",
      "--env",
      "GODOT_SILENCE_ROOT_WARNING=1",
      "--tmpfs",
      "/tmp:rw,nosuid,nodev,size=536870912",
      "--mount",
      `type=bind,source=${workspace},target=/workspace`,
      "--mount",
      `type=bind,source=${godotBinary},target=/usr/local/bin/godot,readonly`,
      "--workdir",
      "/workspace",
      executorImage,
      "--remote",
      remoteUrl,
      "--environment-id",
      environmentId,
    ];

    executor = spawn("docker", dockerArguments, {
      env: dockerEnv,
      stdio: ["ignore", "pipe", "pipe"],
    });
    executor.stdout.on("data", (chunk) => executorLog.write(redact(chunk)));
    executor.stderr.on("data", (chunk) => executorLog.write(redact(chunk)));
    executor.once("error", (error) => {
      connected.reject(error);
      completed.reject(error);
    });
    executor.once("exit", (code) => {
      if (!turnFinished && code !== 0) {
        const error = new Error(`L'exécuteur isolé s'est arrêté avec le code ${code}.`);
        connected.reject(error);
        completed.reject(error);
      }
    });

    await withTimeout(
      connected.promise,
      CONNECTION_TIMEOUT_MS,
      "L'exécuteur n'a pas rejoint la session Agents API dans le délai prévu.",
    );

    const prompt = [
      "TÂCHE AUTORISÉE PAR LE PROPRIÉTAIRE DU DÉPÔT :",
      task,
      "",
      "Contraintes de livraison :",
      "- respecte AGENTS.md et le périmètre CPU ;",
      "- conserve la compatibilité des sauvegardes ;",
      "- exécute les trois contrôles Godot indiqués dans AGENTS.md ;",
      "- écris .agent-output/report.md avec les faits vérifiés, les tests et les risques ;",
      "- ne fais aucun commit, push ou appel GitHub.",
    ].join("\n");

    await client.beta.agents.sessions.events.create(session.id, {
      events: [
        {
          type: "agent.session.input.message",
          input: [
            {
              role: "user",
              content: [{ type: "input_text", text: prompt }],
            },
          ],
        },
      ],
    });

    const requestedTimeout = Number(process.env.AGENT_TIMEOUT_MS || DEFAULT_TIMEOUT_MS);
    const timeoutMs = Math.min(Math.max(requestedTimeout, 60_000), 25 * 60 * 1000);
    try {
      await withTimeout(
        completed.promise,
        timeoutMs,
        "Le temps maximal de travail de l'agent est dépassé.",
      );
      turnFinished = true;
    } catch (error) {
      try {
        await client.beta.agents.sessions.events.create(session.id, {
          events: [{ type: "agent.session.input.cancel" }],
        });
      } catch {
        // La session peut déjà être terminée ou indisponible.
      }
      throw error;
    }

    const items = await client.beta.agents.sessions.items.list(session.id, {
      order: "asc",
      limit: 100,
    });
    await fs.writeFile(
      path.join(outputDirectory, "items.json"),
      redact(JSON.stringify(items, null, 2)),
      "utf8",
    );

    try {
      await fs.access(reportPath);
    } catch {
      await fs.writeFile(
        reportPath,
        "# Rapport incomplet\n\nL'agent a terminé sans produire le rapport demandé. Consulter `items.json` et ne pas appliquer le patch sans revue manuelle.\n",
        "utf8",
      );
    }

    expectedStreamClose = true;
    events.controller.abort();
    await eventPump;
    console.log(`Session ${session.id} terminée ; proposition prête à être collectée.`);
  } finally {
    expectedStreamClose = true;
    if (events?.controller) events.controller.abort();
    if (executor && !executor.killed) executor.kill("SIGTERM");
    executorLog.end();
    await removeContainer(containerName, dockerEnv);
  }
}

main().catch((error) => {
  console.error(`Échec du pilote Agents API : ${redact(error?.message || error)}`);
  process.exitCode = 1;
});
