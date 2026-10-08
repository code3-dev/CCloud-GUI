# LG webOS TV Installation Guide for CCloud

CCloud for LG TVs is a `.ipk` package (`CCloud-webos.ipk` on the releases page). LG TVs only install apps from outside the LG Content Store in **Developer Mode**.

## 1. Enable Developer Mode on the TV

1. Create a free account at [developer.lge.com](https://developer.lge.com).
2. On the TV, install **Developer Mode** from the LG Content Store and sign in with that account.
3. Turn on **Dev Mode Status**, let the TV restart, and open Developer Mode again.
4. Turn on **Key Server** and note the TV's IP address shown there.

## 2. Install the app from a computer

1. Install Node.js, then the webOS CLI:
   ```bash
   npm install -g @webos-tools/cli
   ```
2. Add the TV (use the IP address shown in Developer Mode):
   ```bash
   ares-setup-device --add tv --info "{'host':'192.168.1.20','port':'9922','username':'prisoner'}"
   ares-novacom --device tv --getkey   # enter the passphrase shown in Developer Mode
   ```
3. Install and launch CCloud:
   ```bash
   ares-install --device tv CCloud-webos.ipk
   ares-launch --device tv com.pira.ccloud
   ```

If you prefer a graphical tool, [webOS Dev Manager](https://github.com/webosbrew/dev-manager-desktop) can install the same `.ipk`. On a rooted TV with the Homebrew Channel, you can install the `.ipk` directly.

## Keeping the app

A Developer Mode session lasts about 50 days. When it expires, apps installed this way are removed. To keep them, open the Developer Mode app and press **Extend** before the timer runs out.

## Notes

- **Remote:** use the arrows and OK to move and select, and Back to go back. In the player, OK plays or pauses, ◀/▶ seek 10 seconds, and Yellow changes the quality.
- **Video servers:** most of them only accept connections from Iran. If a video doesn't start, the app says so and you can choose another quality.
