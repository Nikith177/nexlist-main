const { test } = require('@playwright/test');

test.describe('Auth flow trace', () => {
  test.setTimeout(120000);

  test('capture auth, routing, and firestore logs', async ({ browser }) => {
    const context = await browser.newContext();

    const attachPageLogging = (page, label) => {
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
    };

    context.on('page', (page) => {
      if (page.isClosed()) return;
      const label = page.opener() ? 'popup' : 'main';
      attachPageLogging(page, label);
      page
          .waitForLoadState('domcontentloaded', { timeout: 10000 })
          .then(() => console.log(`[${label}] loaded ${page.url()}`))
          .catch(() => {});
    });

    const page = await context.newPage();
    attachPageLogging(page, 'main');

    console.log('TEST 1: Fresh open');
    await page.goto('http://127.0.0.1:7357', { waitUntil: 'domcontentloaded' });
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
    attachPageLogging(backgroundPage, 'background');
    await backgroundPage.goto('about:blank');
    await backgroundPage.bringToFront();
    await page.waitForTimeout(2000);
    await page.bringToFront();
    await page.waitForTimeout(6000);
    console.log(`[main] current url after resume ${page.url()}`);

    await backgroundPage.close().catch(() => {});
    await context.close();
  });
});
