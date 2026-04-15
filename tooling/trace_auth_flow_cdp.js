const { mkdtempSync, rmSync } = require('fs');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');

const chromePath =
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const appUrl = 'http://127.0.0.1:7357';
const debugPort = 9222;

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function waitForJsonEndpoint(timeoutMs = 15000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const response = await fetch(`http://127.0.0.1:${debugPort}/json`);
      if (response.ok) {
        return response.json();
      }
    } catch (_) {}
    await delay(250);
  }
  throw new Error('Timed out waiting for Chrome remote debugging endpoint');
}

async function sendCommand(socket, state, method, params = {}) {
  const id = state.nextId++;
  const payload = { id, method, params };
  socket.send(JSON.stringify(payload));
  return new Promise((resolve, reject) => {
    state.pending.set(id, { resolve, reject, method });
  });
}

async function main() {
  const userDataDir = mkdtempSync(path.join(os.tmpdir(), 'nexlist-trace-'));
  const chrome = spawn(
    chromePath,
    [
      '--headless=new',
      '--disable-gpu',
      `--remote-debugging-port=${debugPort}`,
      '--no-first-run',
      '--no-default-browser-check',
      `--user-data-dir=${userDataDir}`,
      appUrl,
    ],
    {
      stdio: ['ignore', 'pipe', 'pipe'],
    },
  );

  chrome.stdout.on('data', (chunk) => {
    const text = chunk.toString().trim();
    if (text) {
      console.log(`[chrome-stdout] ${text}`);
    }
  });
  chrome.stderr.on('data', (chunk) => {
    const text = chunk.toString().trim();
    if (text) {
      console.log(`[chrome-stderr] ${text}`);
    }
  });

  try {
    const targets = await waitForJsonEndpoint();
    const pageTarget = targets.find(
      (target) => target.type === 'page' && target.url.startsWith(appUrl),
    );
    if (!pageTarget?.webSocketDebuggerUrl) {
      throw new Error(`Could not find page target for ${appUrl}`);
    }

    const socket = new WebSocket(pageTarget.webSocketDebuggerUrl);
    const state = {
      nextId: 1,
      pending: new Map(),
    };

    socket.addEventListener('message', (event) => {
      const payload = JSON.parse(event.data.toString());
      if (payload.id) {
        const pending = state.pending.get(payload.id);
        if (!pending) return;
        state.pending.delete(payload.id);
        if (payload.error) {
          pending.reject(
            new Error(`${pending.method} failed: ${JSON.stringify(payload.error)}`),
          );
        } else {
          pending.resolve(payload.result);
        }
        return;
      }

      if (payload.method === 'Runtime.consoleAPICalled') {
        const args = (payload.params.args || [])
          .map((arg) => arg.value ?? arg.description ?? '[unserializable]')
          .join(' ');
        console.log(`[page-console:${payload.params.type}] ${args}`);
      } else if (payload.method === 'Runtime.exceptionThrown') {
        const details = payload.params.exceptionDetails;
        console.log(
          `[page-exception] ${details.text || details.exception?.description || 'unknown exception'}`,
        );
      } else if (payload.method === 'Log.entryAdded') {
        console.log(
          `[page-log:${payload.params.entry.level}] ${payload.params.entry.text}`,
        );
      }
    });

    await new Promise((resolve, reject) => {
      socket.addEventListener('open', resolve, { once: true });
      socket.addEventListener(
        'error',
        (error) => reject(error.error || error),
        { once: true },
      );
    });

    await sendCommand(socket, state, 'Runtime.enable');
    await sendCommand(socket, state, 'Log.enable');
    await sendCommand(socket, state, 'Page.enable');

    console.log('TEST 1: Fresh open');
    await delay(6000);
    console.log(`[page] current url after fresh open ${pageTarget.url}`);

    console.log('TEST 2: Login flow');
    const clickResult = await sendCommand(socket, state, 'Runtime.evaluate', {
      expression: `(() => {
        const buttons = Array.from(document.querySelectorAll('button'));
        const target = buttons.find((button) =>
          (button.innerText || '').includes('Continue with Student ID'),
        );
        if (!target) return 'button-not-found';
        target.click();
        return 'clicked';
      })()`,
      awaitPromise: true,
      returnByValue: true,
    });
    console.log(
      `[page] login click result ${clickResult.result?.value ?? 'no-result'}`,
    );
    await delay(6000);
    const postClickTargets = await waitForJsonEndpoint(3000);
    const targetSummary = postClickTargets
      .filter((target) => target.type === 'page')
      .map((target) => target.url)
      .join(' | ');
    console.log(`[page] targets after login click ${targetSummary}`);

    console.log('TEST 3: Refresh page');
    await sendCommand(socket, state, 'Page.reload', { ignoreCache: true });
    await delay(6000);

    console.log('TEST 4: Background to resume');
    try {
      await sendCommand(socket, state, 'Page.setWebLifecycleState', {
        state: 'frozen',
      });
      await delay(2000);
      await sendCommand(socket, state, 'Page.setWebLifecycleState', {
        state: 'active',
      });
    } catch (error) {
      console.log(`[page] lifecycle simulation failed ${error.message}`);
    }
    await delay(6000);

    socket.close();
  } finally {
    chrome.kill('SIGTERM');
    rmSync(userDataDir, { recursive: true, force: true });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
