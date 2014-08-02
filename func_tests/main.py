import re
from unittest import TestCase, main
import selenium.webdriver

class NewVisitorTest(TestCase):

    @classmethod
    def setUpClass(cls):
        options = selenium.webdriver.ChromeOptions()
        options.binary_location = r"C:\darteditor-windows-x64\dart\chromium\chrome.exe"
        cls.browser = selenium.webdriver.Chrome(
            executable_path=r"C:\chromedriver_win32\chromedriver.exe",
            chrome_options=options,
            )

    @classmethod
    def tearDownClass(cls):
        cls.browser.quit()

    def test_can_start_a_new_mind_map(self):
        brow = self.browser
        # Regina clicks a link by accident
        brow.get('http://localhost:4040/')

        # It takes her to a page about Mind Maps
        self.assertIn("MindMap", brow.title)
        header = brow.find_element_by_tag_name('h1')
        self.assertIn("Mind Map", header.text)

        # There's a button to create a new one, which she presses
        create = brow.find_element_by_css_selector("button#create")
        create.click()

        mapRe = re.compile('/map/(\d+)')
        # It takes her to a new mind map url
        self.assertRegex(brow.current_url, mapRe)

        # It's still a MindMap and has an indicator for the mind maps ID
        self.assertIn("MindMap", brow.title)
        mapNum = mapRe.search(brow.current_url).group(1)
        indicator = brow.find_element_by_id('idIndicator')
        self.assertIn(mapNum, indicator.text)

        self.fail('Finish the tests')

        # There's a place to create the root

        # She creates a root herbs

        # she adds a couple of other nodes under herbs

        # she leaves and comes back

if __name__ == "__main__":
    main()