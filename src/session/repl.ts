import { prompt } from "../util/prompt.js";
import {
  promptCredentials,
  hydrateCredentials,
  selectApp,
  selectProduct,
  printAuthInstructions,
  type Credentials,
  type Product,
} from "./prompt.js";
import { loadConfig, saveConfig, clearConfig, configPath } from "../storage/config.js";
import { TokenCache } from "../auth/session.js";
import { AscClient } from "../api/client.js";
import { listApps, type App } from "../api/apps.js";
import { listSubscriptions } from "../api/subscriptions.js";
import { listInAppPurchases } from "../api/iaps.js";

interface AuthedState {
  authed: true;
  creds: Credentials;
  client: AscClient;
  app: App | null;
  product: Product | null;
}
interface UnauthedState {
  authed: false;
}
type State = AuthedState | UnauthedState;

const Action = {
  Auth: "auth",
  Help: "help",
  Apps: "apps",
  Logout: "logout",
  Exit: "exit",
} as const;
type Action = (typeof Action)[keyof typeof Action];

interface Choice {
  name: Action;
  message: string;
}

const UNAUTHED_CHOICES: Choice[] = [
  { name: Action.Auth, message: "auth   — enter App Store Connect API credentials" },
  { name: Action.Help, message: "help   — how to generate an API key" },
  { name: Action.Exit, message: "exit   — quit the session" },
];

const AUTHED_CHOICES: Choice[] = [
  { name: Action.Apps,   message: "apps   — list and pick an app to work on" },
  { name: Action.Logout, message: "logout — forget cached credentials" },
  { name: Action.Exit,   message: "exit   — quit the session" },
];

export async function runSession(): Promise<void> {
  let state: State = await bootstrap();

  for (;;) {
    const choices = state.authed ? AUTHED_CHOICES : UNAUTHED_CHOICES;
    const { action } = await prompt<{ action: Action }>({
      type: "select",
      name: "action",
      message: "What next?",
      choices,
    });

    try {
      switch (action) {
        case Action.Exit:
          console.log("bye.");
          return;
        case Action.Auth:
          state = await runAuth();
          break;
        case Action.Help:
          printAuthInstructions();
          break;
        case Action.Apps:
          if (state.authed) state = await runApps(state);
          break;
        case Action.Logout:
          state = await runLogout();
          break;
      }
    } catch (err) {
      console.error(err instanceof Error ? err.message : err);
    }
  }
}

async function bootstrap(): Promise<State> {
  const cfg = await loadConfig();
  if (!cfg) {
    console.log("No cached credentials.");
    return { authed: false };
  }

  try {
    const creds = await hydrateCredentials({
      keyPath: cfg.keyPath,
      keyId: cfg.keyId,
      issuerId: cfg.issuerId,
    });
    console.log(`Using cached credentials (Key ID: ${creds.keyId}).`);
    return enterAuthed(creds);
  } catch (err) {
    console.error(
      `Failed to use cached credentials: ${err instanceof Error ? err.message : err}`,
    );
    return { authed: false };
  }
}

async function runAuth(): Promise<State> {
  const creds = await promptCredentials();
  await saveConfig({
    keyPath: creds.keyPath,
    keyId: creds.keyId,
    issuerId: creds.issuerId,
  });
  console.log(`Saved credentials to ${configPath()}`);
  return enterAuthed(creds);
}

async function runLogout(): Promise<State> {
  const removed = await clearConfig();
  if (removed) {
    console.log("Cached credentials cleared.");
  } else {
    console.log("No cached credentials to clear.");
  }
  return { authed: false };
}

function enterAuthed(creds: Credentials): AuthedState {
  return {
    authed: true,
    creds,
    client: new AscClient(new TokenCache(creds)),
    app: null,
    product: null,
  };
}

async function runApps(state: AuthedState): Promise<AuthedState> {
  console.log("Fetching your apps…");
  const apps = await listApps(state.client);
  const app = await selectApp(apps);
  console.log(`\nWorking on: ${app.name} (${app.bundleId})\n`);

  console.log("Fetching subscriptions and in-app purchases…");
  const [subs, iaps] = await Promise.all([
    listSubscriptions(state.client, app.id),
    listInAppPurchases(state.client, app.id),
  ]);
  const product = await selectProduct(subs, iaps);
  console.log(`\nSelected: ${product.name} (${product.productId})\n`);

  return { ...state, app, product };
}
