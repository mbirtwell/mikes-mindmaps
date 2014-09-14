import re
from unittest import TestCase, main
from selenium.common.exceptions import StaleElementReferenceException, WebDriverException
import selenium.webdriver
import time


def waitFor(func, timeout=3):
    timeout = time.time() + timeout

    while timeout > time.time():
        try:
            return func()
        except (AssertionError, WebDriverException):
            time.sleep(0.1)

    return func()

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
        browser.implicitly_wait(2)
        return browser

    def tearDown(self):
        while self.browsers:
            self.browsers.pop().quit()

    def assertNodeTexts(self, person, expected):
        nodes = person.find_elements_by_css_selector('.node')
        texts = {node.find_element_by_css_selector('span').text
                 for node in nodes}
        self.assertSetEqual(texts, expected)

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
        waitFor(lambda: self.assertRaises(
            StaleElementReferenceException,
            lambda: input.location_once_scrolled_into_view,
        ), timeout=1)
        # And there is no other addnode
        self.assertEqual(len(regina.find_elements_by_css_selector('.addnode')), 0)

        node = regina.find_element_by_css_selector('.node')
        # The node text is what regina typed in
        self.assertEqual(node.find_element_by_css_selector('span').text, 'herbs')
        # The node has 6 buttons for add new nodes
        self.assertEqual(len(node.find_elements_by_css_selector('.node-plus')), 6)

        # She decides to click one
        node.find_element_by_css_selector('.bottom-right').click()
        # Clicking one of the plus buttons creates a new addnode
        addNode = regina.find_element_by_css_selector('.addnode')
        # enters text and clicks add
        input = addNode.find_element_by_css_selector('textarea')
        input.send_keys('rosemary')
        addNode.find_element_by_css_selector('button').click()

        # There's now two nodes with what regina typed
        self.assertNodeTexts(regina, {'herbs', 'rosemary'})

        # Regina gives the link for her mind map to edith
        edith = self.makeBrowser()
        edith.get(mapUrl)

        # The page has the same stuff on it as when regina left it
        self.assertNodeTexts(edith, {'herbs', 'rosemary'})


if __name__ == "__main__":
    main()