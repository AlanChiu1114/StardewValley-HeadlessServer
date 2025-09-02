# 星露谷物語「無頭」伺服器（Docker 一鍵架設）

以 Docker 一鍵架設星露谷物語多人伺服器，不用開啟遊戲視窗也能持續運作。已內建 SMAPI 4.3.2 與 JunimoServer 模組，支援「無玩家時自動暫停時間」、「新玩家加入自動拓展小屋」等伺服器最佳化。

## 這是什麼？
- 以 Linux 容器執行 Stardew Valley（含 SMAPI 與 JunimoServer 模組）。
- 支援長時間穩定運作、玩家可隨時加入。
- 具備「無玩家時自動暫停時間」功能，沒人在線就不會白白流逝遊戲內時間。
- 內建一些自動化與效能優化（關閉不必要的渲染、虛擬顯示等）。

主要依賴的模組/工具：
- SMAPI 4.3.2
- JunimoServer（提供自動化、無玩家暫停、伺服器管理、小屋自動拓展等功能）

## 版本相容性
- 遊戲本體：Stardew Valley 1.6.9正式版(環境建置時透過steamcmd下載)。
- SMAPI：4.3.2（已內建於映像）。
- 模組：JunimoServer 1.0.2-alpha（已內建，建置時從專案原始碼編譯）。

注意：
- 若日後遊戲更新造成不相容，請更新本專案（或等待作者更新）後重新建置；或暫時不要重建，以保留既有可用版本。
- 本專案以 Linux 版遊戲檔運作；不支援直接使用 Windows/macOS 版遊戲檔(環境建置時會自動下載)。

## 取得專案原始碼
下載 ZIP（最簡單）
- 開啟此專案的 GitHub 頁面。
- 點擊綠色「Code」按鈕 >「Download ZIP」。
- 將壓縮檔解壓縮到你想放置的位置。

接著依照下方「準備環境」與「快速開始」繼續。

## 準備環境
1) 安裝 Docker Desktop（Windows，需使用 Linux 容器模式）。
2) 建立環境變數檔 `.env`（放在專案根目錄）：
   - 請先將 `.env.example` 複製為 `.env`，並填入：
     - `STEAM_USERNAME=你的Steam帳號`
     - `STEAM_PASSWORD=你的Steam密碼`

## 快速開始
在專案根目錄開啟 Windows PowerShell，依序執行：

1) 建置映像（第一次會下載遊戲檔與安裝模組）
```powershell
docker compose build
```
在建置過程中，Steam 可能要求你進行手機 App 驗證。請打開手機 Steam App 並「同意登入」。系統會每 30 秒重試一次，按同意後會自動繼續。

2) 啟動伺服器（背景執行）
```powershell
docker compose up -d
```

3) 查看伺服器日誌（確認已載入到主選單/存檔）
```powershell
docker compose logs -f
```

4) 連線到伺服器
- 在遊戲中選「加入多人遊戲」，伺服器位址輸入：`127.0.0.1:24642`
- 若同一網路的其他電腦要加入，請輸入你這台電腦的內網 IP（例如 `192.168.x.x:24642`），並確認防火牆已允許 24642/tcp 與 24642/udp。

常用指令：
- 停止伺服器：
```powershell
docker compose down
```
- 重新啟動伺服器：
```powershell
docker compose up -d
```

## 資料保存（Saves、設定）
提示：星露谷的存檔是「每日結束後自動保存」。只有在一天結束（角色睡覺後、結算畫面跑完）才會把進度寫入存檔；中途離開或直接關閉伺服器不會保存當日進度。建議在當天結束後再停止伺服器。

容器環境已包含持久化存檔，把遊戲資料對映到本機的 `./data` 目錄：
- 本機 `./data` ↔ 容器 `/data`
- 存檔路徑（本機）：`./data/StardewValley/Saves`
- SMAPI/模組設定資料（本機）：`./data/StardewValley/.smapi`

### 匯入自己的存檔（放進伺服器）
1) 停止伺服器（避免寫入衝突）：
```powershell
docker compose down
```
2) 將你的存檔資料夾（例如 `MyFarm_123456789`，裡面包含同名檔案與 `SaveGameInfo`）整個複製到：
```
./data/StardewValley/Saves/
```
3) 指定啟動時要載入的存檔：編輯（若不存在請先啟動一次伺服器再停止，它會自動建立）
```
./data/StardewValley/.smapi/mod-data/junimohost.server/junimohost.gameloader.json
```
將其中的 `SaveNameToLoad` 改成你的存檔資料夾名稱，例如：
```json
{ "SaveNameToLoad": "MyFarm_123456789" }
```
4) 啟動伺服器：
```powershell
docker compose up -d
```

重要提醒：把「已在你個人電腦上進行中的存檔」直接搬到伺服器使用，可能會導致「主要角色變成伺服器主機」等權限/角色歸屬問題，不太建議。如果要嘗試，請務必先備份原存檔。

### 將伺服器存檔搬回本機遊玩
從本機專案的 `./data/StardewValley/Saves` 裡，把目標存檔資料夾整個複製回電腦的星露谷存檔位置即可。例如：
```
C:\Users\USERNAME\AppData\Roaming\StardewValley\Saves
```
（請將 `USERNAME` 換成你自己的 Windows 使用者名稱）

## 連線埠
- 對外開放：`24642/tcp` 與 `24642/udp`(若要開啟對外連線須設定Port Forwarding或直接使用VPN)
- 本機連線：`127.0.0.1:24642`
- 區網他機連線：192.168...(使用cmd輸入ipconfig查看ipv4)

## 更新遊戲/模組
此映像在執行期不包含 steamcmd，自動更新未啟用；需要更新時，請在專案根目錄重新建置並重啟：
```powershell
docker compose build
docker compose up -d
```

## 疑難排解
- 建置卡住等待 Steam 驗證：請到手機 Steam App 同意登入，系統會自動重試並繼續。
- 環境建置遇到問題請使用 `docker compose down -v --rmi local --remove-orphans; docker compose up -d --build` 嘗試重建。
- 帳密錯誤：請確認 `.env` 的 `STEAM_USERNAME`/`STEAM_PASSWORD` 正確，修正後重新 `docker compose build`。
- 連線不到伺服器：確認容器正在執行、連線埠 24642 已打開、防火牆規則允許，並使用正確 IP。
