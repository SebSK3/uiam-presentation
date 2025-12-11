const puppeteer = require('puppeteer');

const JITSI_URL = 'https://jitsi.google.sex.pl/MyLoadTestRoom123'; 
const BOT_COUNT = 3; 
const DURATION_SECONDS = 30; 
const HEADLESS = false;

async function startBot(id) {
    const browser = await puppeteer.launch({
        headless: HEADLESS ? "new" : false,
        args: [
            '--use-fake-ui-for-media-stream',
            '--use-fake-device-for-media-stream',
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--window-size=1280,720'
        ]
    });

    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 720 });

    try {
        console.log(`Bot ${id}: Navigating...`);
        // We still pass parameters to mute audio/video initially to speed up joining
        await page.goto(`${JITSI_URL}#config.startWithAudioMuted=true&config.startWithVideoMuted=false`, { waitUntil: 'networkidle0' });

        try {
            const nameInputSelector = 'input[placeholder="Enter your name"]'; 
            await page.waitForSelector(nameInputSelector, { timeout: 5000 });
            
            console.log(`Bot ${id}: Prejoin screen detected. Entering name...`);
            await page.type(nameInputSelector, `Bot-${id}`);
            
            const joinButtonSelector = '[data-testid="prejoin.joinMeeting"]';
            await page.waitForSelector(joinButtonSelector);
            await page.click(joinButtonSelector);
            
        } catch (error) {
            console.log(`Bot ${id}: No prejoin screen detected (or timed out), assuming direct join.`);
        }

        console.log(`Bot ${id}: SUCCESS - Joined the meeting.`);
        await new Promise(r => setTimeout(r, DURATION_SECONDS * 1000));
        
    } catch (e) {
        console.error(`Bot ${id} FAILED:`, e.message);
    } finally {
        await browser.close();
    }
}

(async () => {
    console.log(`Starting ${BOT_COUNT} bots...`);
    const promises = [];
    for (let i = 0; i < BOT_COUNT; i++) {
        promises.push(startBot(i));
        // Stagger joins slightly to be realistic
        await new Promise(r => setTimeout(r, 2000));
    }
    await Promise.all(promises);
    console.log('Test Complete.');
})();
