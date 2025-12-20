from playwright.sync_api import sync_playwright
import sys, time

url = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8081"
print(f"Capturing console for: {url}")
with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()

    def on_console(msg):
        try:
            print(f"CONSOLE {msg.type}: {msg.text}")
        except Exception as e:
            print("CONSOLE (error printing):", e)

    page.on("console", on_console)
    page.on("pageerror", lambda e: print("PAGE_ERROR:", e))
    page.on("requestfailed", lambda r: print("REQUEST_FAILED:", r.url, r.failure))

    page.goto(url, wait_until="load", timeout=30000)
    # wait a bit for async logs
    time.sleep(2)
    browser.close()
    print("Done capturing.")
