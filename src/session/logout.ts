import { prompt } from "../util/prompt.js";
import { clearConfig, configPath } from "../storage/config.js";

export async function runLogout(): Promise<void> {
  const { confirmed } = await prompt<{ confirmed: boolean }>({
    type: "confirm",
    name: "confirmed",
    message: "Forget cached credentials?",
    initial: false,
  });
  if (!confirmed) {
    console.log("Logout cancelled.");
    return;
  }
  const removed = await clearConfig();
  if (removed) {
    console.log(`Cleared cached credentials at ${configPath()}`);
  } else {
    console.log("No cached credentials to clear.");
  }
}
