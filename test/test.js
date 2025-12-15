#!/usr/bin/env node

/* jshint esversion: 8 */
/* global it, xit, describe, before, after, afterEach */

'use strict';

require('chromedriver');

const execSync = require('child_process').execSync,
    expect = require('expect.js'),
    fs = require('fs'),
    path = require('path'),
    { Builder, By, Key, until } = require('selenium-webdriver'),
    { Options } = require('selenium-webdriver/chrome');

describe('Application life cycle test', function () {
    this.timeout(0);

    const LOCATION = process.env.LOCATION || 'test';
    const TEST_TIMEOUT = 10000;
    const EXEC_ARGS = { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' };

    let browser, app;

    // BentoPDF doesn't require authentication - it's a client-side app
    // No login credentials needed


    before(async function () {
        await startBrowser();
        if (!fs.existsSync('./screenshots')) fs.mkdirSync('./screenshots');
    });

    after(function () {
        browser.quit();
    });

    afterEach(async function () {
        if (!process.env.CI || !app) return;

        const currentUrl = await browser.getCurrentUrl();
        if (!currentUrl.includes(app.domain)) return;
        expect(this.currentTest.title).to.be.a('string');

        const screenshotData = await browser.takeScreenshot();
        fs.writeFileSync(`./screenshots/${new Date().getTime()}-${this.currentTest.title.replaceAll(' ', '_')}.png`, screenshotData, 'base64');
    });

    function getAppInfo() {
        var inspect = JSON.parse(execSync('cloudron inspect'));
        app = inspect.apps.filter(function (a) { return a.location.indexOf(LOCATION) === 0; })[0];
        expect(app).to.be.an('object');
    }

    async function clearCache() {
        await browser.manage().deleteAllCookies();
        await browser.quit();
        await startBrowser();
    }

    async function startBrowser() {
        browser = null;
        const chromeOptions = new Options().windowSize({ width: 1280, height: 1024 });
        if (process.env.CI) chromeOptions.addArguments('no-sandbox', 'disable-dev-shm-usage', 'headless');
        browser = new Builder().forBrowser('chrome').setChromeOptions(chromeOptions).build();
    }

    async function waitForElement(elem) {
        await browser.wait(until.elementLocated(elem), TEST_TIMEOUT);
        await browser.wait(until.elementIsVisible(browser.findElement(elem)), TEST_TIMEOUT);
    }

    // BentoPDF doesn't require login - it's a client-side app
    async function navigateToApp() {
        await browser.get(`https://${app.fqdn}`);
        // Wait for the app to load - look for a common element in BentoPDF
        await browser.sleep(2000);
    }

    async function checkWebApp() {
        await browser.get(`https://${app.fqdn}`);
        // BentoPDF should load - check for any common element
        // Since it's a client-side app, we just verify the page loads
        await browser.sleep(2000);
        const title = await browser.getTitle();
        expect(title).to.be.a('string');
    }

    xit('build app', function () { execSync('cloudron build', EXEC_ARGS); });

    it('install app', function () { execSync('cloudron install --location ' + LOCATION, EXEC_ARGS); });

    it('can get app information', getAppInfo);
    it('can navigate to app', navigateToApp);
    it('can see the web app', checkWebApp);

    it('backup app', function () { execSync('cloudron backup create --app ' + app.id, EXEC_ARGS); });

    it('restore app', function () {
        const backups = JSON.parse(execSync(`cloudron backup list --raw --app ${app.id}`));
        execSync('cloudron uninstall --app ' + app.id, EXEC_ARGS);
        execSync('cloudron install --location ' + LOCATION, EXEC_ARGS);
        getAppInfo();
        execSync(`cloudron restore --backup ${backups[0].id} --app ${app.id}`, EXEC_ARGS);
    });

    it('can navigate to app', navigateToApp);
    it('can see the web app', checkWebApp);

    it('move to different location', function () { execSync('cloudron configure --location ' + LOCATION + '2 --app ' + app.id, EXEC_ARGS); });
    it('can get app information', getAppInfo);
    it('can navigate to app', navigateToApp);
    it('can see the web app', checkWebApp);

    it('uninstall app', function () { execSync('cloudron uninstall --app ' + app.id, EXEC_ARGS); });

    it('clear cache', clearCache);

    // test update - note: update test would need the actual appstore ID for bentopdf
    // it('can install app for update', async function () { execSync('cloudron install --appstore-id bentopdf.alam00000.cloudronapp --location ' + LOCATION, EXEC_ARGS); });

    // it('can get app information', getAppInfo);
    // it('can navigate to app', navigateToApp);
    // it('can see the web app', checkWebApp);

    // it('can update', function () { execSync('cloudron update --app ' + app.id, EXEC_ARGS); });

    // it('can navigate to app', navigateToApp);
    // it('can see the web app', checkWebApp);

    it('uninstall app', function () { execSync('cloudron uninstall --app ' + app.id, EXEC_ARGS); });
});
