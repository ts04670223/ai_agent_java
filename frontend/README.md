# React 聊天系統前端

這是一個基於 React + Vite 的現代化聊天系統前端應用。

## 功能特點

✅ 會員註冊和登入系統
✅ 雙向即時聊天
✅ 聯絡人列表
✅ 訊息歷史記錄
✅ 自動刷新訊息（每3秒）
✅ 美觀的現代化 UI
✅ 響應式設計

## 技術棧

- React 18
- React Router 6
- Axios
- Vite

## 安裝步驟

### 1. 安裝依賴

```bash
cd frontend
npm install
```

### 2. 啟動開發伺服器

```bash
npm run dev
```

應用程式將在 `http://localhost:3000` 啟動

### 3. 確保後端運行

確保 Spring Boot 後端應用程式在 `http://localhost:8080` 運行

```bash
cd ..
mvn spring-boot:run
```

## 使用說明

### 註冊新帳號

1. 訪問 `http://localhost:3000`
2. 點擊「立即註冊」
3. 填寫用戶名、姓名、郵箱和密碼
4. 點擊「註冊」按鈕

### 登入

1. 輸入用戶名和密碼
2. 點擊「登入」按鈕

### 開始聊天

1. 從左側聯絡人列表選擇一個用戶
2. 在底部輸入框輸入訊息
3. 按 Enter 或點擊「發送」按鈕
4. 訊息會自動每3秒刷新

### 測試雙向對話

1. 開啟兩個瀏覽器視窗或使用無痕模式
2. 在第一個視窗註冊並登入為用戶A
3. 在第二個視窗註冊並登入為用戶B
4. 兩個用戶之間可以即時聊天

## 專案結構

```
frontend/
├── public/
├── src/
│   ├── pages/
│   │   ├── Login.jsx          # 登入頁面
│   │   ├── Register.jsx       # 註冊頁面
│   │   ├── Chat.jsx           # 聊天頁面
│   │   ├── Auth.css           # 登入/註冊樣式
│   │   └── Chat.css           # 聊天頁面樣式
│   ├── App.jsx                # 主應用程式組件
│   ├── api.js                 # API 呼叫函數
│   ├── main.jsx               # 入口檔案
│   └── index.css              # 全域樣式
├── index.html
├── package.json
└── vite.config.js
```

## API 端點

### 認證相關
- `POST /api/auth/register` - 註冊新用戶
- `POST /api/auth/login` - 用戶登入
- `GET /api/auth/users` - 獲取所有用戶列表
- `GET /api/auth/users/{id}` - 獲取單個用戶信息

### 聊天相關
- `POST /api/chat/send` - 發送訊息
- `GET /api/chat/history?user1={id1}&user2={id2}` - 獲取聊天記錄
- `GET /api/chat/unread/{userId}` - 獲取未讀訊息
- `PUT /api/chat/read-chat` - 標記對話為已讀

## 建構生產版本

```bash
npm run build
```

建構後的檔案將在 `dist` 目錄中。

## 預覽生產版本

```bash
npm run preview
```

## 注意事項

1. **密碼安全**: 當前版本密碼為明文儲存，生產環境應使用加密（如 BCrypt）
2. **會話管理**: 使用 localStorage 儲存用戶信息，生產環境應使用 JWT 或 Session
3. **訊息刷新**: 目前使用輪詢（3秒一次），可以升級為 WebSocket 實現真正的即時通訊
4. **CORS**: 開發環境使用 Vite proxy，生產環境需要配置後端 CORS

## 開發建議

### 未來改進方向

- [ ] 實作 WebSocket 即時通訊
- [ ] 新增檔案上傳功能
- [ ] 新增表情符號支援
- [ ] 新增訊息已讀狀態顯示
- [ ] 新增群組聊天功能
- [ ] 新增訊息搜尋功能
- [ ] 新增密碼加密
- [ ] 實作 JWT 認證
