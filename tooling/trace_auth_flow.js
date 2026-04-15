const { chromium } = require('playwright');

const targetUrl = 'http://127.0.0.1:7357';

function attachLogging(page, label) {
  page.on('console', (msg) => {
    console.log(`[${label}] console:${msg.type()} ${msg.text()}`);
  });
  page.on('pageerror', (error) => {
    console.log(`[${label}] pageerror ${error.message}`);
  });
  page.on('requestfailed', (request) => {
    console.log(
      `[${label}] requestfailed ${request.method()} ${request.url()} ${request.failure()?.errorText}`,
    );
  });
}

async function main() {
  const browser = await chromium.launch({
    channel: 'chrome',
    headless: true,
  });
  const context = await browser.newContext();
  const page = await context.newPage();

  attachLogging(page, 'main');

  context.on('page', async (popup) => {
    if (popup === page) return;
    attachLogging(popup, 'popup');
    try {
      await popup.waitForLoadState('domcontentloaded', { timeout: 10000 });
      console.log(`[popup] loaded ${popup.url()}`);
    } catch (error) {
      console.log(`[popup] load wait failed ${error.message}`);
    }
  });

  console.log('TEST 1: Fresh open');
  await page.goto(targetUrl, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(6000);
  console.log(`[main] current url after fresh open ${page.url()}`);

  console.log('TEST 2: Login flow');
  const loginButton = page.getByRole('button', {
    name: /Continue with Student ID/i,
  });
  if (await loginButton.isVisible().catch(() => false)) {
    const popupPromise = context
      .waitForEvent('page', { timeout: 8000 })
      .catch(() => null);
    await loginButton.click();
    const popup = await popupPromise;
    if (popup) {
      await popup.waitForTimeout(5000);
      console.log(`[popup] current url after login click ${popup.url()}`);
      await popup.close().catch(() => {});
    } else {
      console.log('[main] login popup did not open');
    }
  } else {
    console.log('[main] login button not visible');
  }
  await page.waitForTimeout(6000);
  console.log(`[main] current url after login flow ${page.url()}`);

  console.log('TEST 3: Refresh page');
  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(6000);
  console.log(`[main] current url after refresh ${page.url()}`);

  console.log('TEST 4: Background to resume');
  const backgroundPage = await context.newPage();
  attachLogging(backgroundPage, 'background');
  await backgroundPage.goto('about:blank');
  await backgroundPage.bringToFront();
  await page.waitForTimeout(2000);
  await page.bringToFront();
  await page.waitForTimeout(6000);
  console.log(`[main] current url after resume ${page.url()}`);
  await backgroundPage.close().catch(() => {});

  await context.close();
  await browser.close();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
