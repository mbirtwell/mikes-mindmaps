import selenium.webdriver

options = selenium.webdriver.ChromeOptions()
options.binary_location = r"C:\darteditor-windows-x64\dart\chromium\chrome.exe"
browser = selenium.webdriver.Chrome(
    executable_path=r"C:\chromedriver_win32\chromedriver.exe",
    chrome_options=options,
)
browser.get('http://localhost:4040/')
assert "MindMap" in browser.title