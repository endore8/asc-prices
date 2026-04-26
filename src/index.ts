#!/usr/bin/env node
import { Command } from "commander";
import { runSession } from "./session/repl.js";

const program = new Command();

program
  .name("asc-prices")
  .description(
    "Preview and apply PPP-aligned App Store subscription and in-app purchase prices",
  )
  .version("0.0.1")
  .action(async () => {
    await runSession();
  });

program.parseAsync(process.argv).catch((err) => {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
});
