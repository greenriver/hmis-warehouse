'use strict';
// pdf generation with puppeteer
// https://github.com/GoogleChrome/puppeteer

const puppeteer = require('puppeteer');

const createPdf = async() => {
  const [_node, _path, docUrl, outputPath, chromePath] = process.argv;
  let browser;
  try {
    browser = await puppeteer.launch({
      ignoreHTTPSErrors: true,
      executablePath: chromePath,
      args: [
        '--no-sandbox',
        '--disable-dev-shm-usage'
      ]
    });
    const page = await browser.newPage();
    await page.goto(docUrl, {timeout: 12000, waitUntil: 'networkidle2'});
    await page.waitFor(600);
    const pdf = await page.pdf({
      path: outputPath,
      format: 'Letter',
      margin: {top: '1.5cm', right: '1.5cm', bottom: '1.5cm', left: '1.5cm'},
      printBackground: true,
      displayHeaderFooter: true,
      headerTemplate: '<div/>',
      footerTemplate: "<div><style type='text/css'>div { font-size: 8px; text-align: right; margin-right: 20px; width: 100%; }</style> Page <span class='pageNumber'></span> of <span class='totalPages'></span></div>",
    });
  } catch (err) {
      console.log(err.message);
  } finally {
    if (browser) {
      browser.close();
    }
    process.exit();
  }
};
createPdf();
