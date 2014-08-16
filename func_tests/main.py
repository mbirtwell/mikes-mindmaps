import re
from unittest import TestCase, main
from selenium.common.exceptions import StaleElementReferenceException
import selenium.webdriver

class NewVisitorTest(TestCase):

    browsers = []

    def makeBrowser(self):
        options = selenium.webdriver.ChromeOptions()
        options.binary_location = r"C:\darteditor-windows-x64\dart\chromium\chrome.exe"
        browser = selenium.webdriver.Chrome(
            executable_path=r"C:\chromedriver_win32\chromedriver.exe",
            chrome_options=options,
            )
        self.browsers.append(browser)
        return browser

    def tearDown(self):
        while self.browsers:
            self.browsers.pop().quit()

    def test_can_start_a_new_mind_map(self):
        regina = self.makeBrowser()
        # Regina clicks a link by accident
        regina.get('http://localhost:4040/')

        # It takes her to a page about Mind Maps
        self.assertIn("MindMap", regina.title)
        header = regina.find_element_by_tag_name('h1')
        self.assertIn("Mind Map", header.text)

        # There's a button to create a new one, which she presses
        create = regina.find_element_by_css_selector("button#create")
        create.click()

        mapUrl = regina.current_url
        mapRe = re.compile('/map/(\d+)')
        # It takes her to a new mind map url
        self.assertRegex(mapUrl, mapRe)

        # It's still a MindMap and has an indicator for the mind maps ID
        self.assertIn("MindMap", regina.title)
        mapNum = mapRe.search(mapUrl).group(1)
        indicator = regina.find_element_by_id('idIndicator')
        self.assertIn(mapNum, indicator.text)

        # There's a place to create the root
        input = regina.find_element_by_css_selector('textarea')

        # She enters the text for her root: herbs
        input.send_keys('herbs')
        # ... and there's an associated button
        add = regina.find_element_by_css_selector('.addnode button')
        # it says add
        self.assertEqual(add.text, 'Add')
        # so she presses it
        add.click()
        #  it doesn't go any where
        self.assertEqual(regina.current_url, mapUrl)
        # but the text area has been replaced by the new node
        self.assertRaises(StaleElementReferenceException,
                          lambda: input.location_once_scrolled_into_view)
        node = regina.find_element_by_css_selector('.node span')
        self.assertEqual(node.text, 'herbs')

        self.fail('Finish the tests')

        # she adds a couple of other nodes under herbs

        # she leaves and comes back

if __name__ == "__main__":
    main()