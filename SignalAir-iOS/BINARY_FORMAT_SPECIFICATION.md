# 二進制編碼器/解碼器格式規範

## 🔧 協議常數
- **協議版本**: 1 (UInt8)
- **最小頭部大小**: 10 bytes
- **最大ID長度**: 64 bytes
- **最大字符串長度**: 64 bytes

## 📦 標準 MeshMessage 格式

### 編碼格式 (BinaryMessageEncoder.encode)
```
偏移量  大小     描述                         格式
------  ----     ----                         ----
0       1 byte   協議版本                     UInt8 (固定值: 1)
1       1 byte   訊息類型                     UInt8 (MeshMessageType.rawValue)
2       1 byte   訊息ID長度                   UInt8 (1-64)
3       N bytes  訊息ID                       UTF-8字符串
3+N     4 bytes  數據長度                     UInt32 (Little Endian)
7+N     4 bytes  時間戳                       UInt32 (Little Endian, Unix時間)
11+N    M bytes  實際數據                     原始數據
```

### 解碼流程 (BinaryMessageDecoder.decode)
1. **驗證協議版本**: 必須為 1
2. **解析訊息類型**: 必須是有效的 MeshMessageType
3. **讀取ID**: 
   - 讀取ID長度 (1-64 bytes)
   - 讀取ID內容並正規化 (移除$前綴，驗證UUID格式)
4. **讀取數據長度**: 4 bytes, Little Endian
5. **讀取時間戳**: 4 bytes, Little Endian
6. **讀取實際數據**: 根據數據長度讀取

## 💬 聊天訊息格式

### ChatViewModel 編碼格式 (encodeChatMessageToBinary)
```
偏移量  大小     描述                         格式
------  ----     ----                         ----
0       4 bytes  時間戳                       UInt32 (Little Endian)
4       1 byte   設備名稱長度                 UInt8
5       N bytes  設備名稱                     UTF-8字符串
5+N     1 byte   訊息ID長度                   UInt8
6+N     M bytes  訊息ID                       UTF-8字符串
6+N+M   2 bytes  訊息內容長度                 UInt16 (Little Endian)
8+N+M   P bytes  訊息內容                     UTF-8字符串
```

### BinaryMessageEncoder.encodeChatMessage 格式
```
偏移量  大小     描述                         格式
------  ----     ----                         ----
0       1 byte   協議版本                     UInt8 (固定值: 1)
1       1 byte   訊息類型                     UInt8 (值: 3 = chat)
2       4 bytes  時間戳                       UInt32 (Little Endian)
6       1 byte   設備名稱長度                 UInt8
7       N bytes  設備名稱                     UTF-8字符串
7+N     1 byte   訊息ID長度                   UInt8
8+N     M bytes  訊息ID                       UTF-8字符串
8+N+M   2 bytes  訊息內容長度                 UInt16 (Little Endian)
10+N+M  P bytes  訊息內容                     UTF-8字符串
```

### 完整聊天訊息發送流程
1. **ChatViewModel.sendMessage()**:
   - 創建 ChatMessage 對象
   - 使用 `encodeChatMessageToBinary()` 編碼為二進制
   - 包裝成 MeshMessage(type: .chat, data: 二進制數據)
   - 使用 `BinaryMessageEncoder.encode()` 編碼整個 MeshMessage
   - 結果: 雙層編碼格式

2. **發送格式結構**:
```
[MeshMessage 頭部]
  - 協議版本 (1)
  - 訊息類型 (3)
  - 訊息ID長度 + ID
  - 數據長度
  - 時間戳
[ChatMessage 二進制數據]
  - 時間戳
  - 設備名稱長度 + 名稱
  - 訊息ID長度 + ID
  - 訊息內容長度 + 內容
```

## 🔐 加密層

### 加密前格式
- 標準 MeshMessage 二進制格式

### 加密後格式
- ChaCha20-Poly1305 加密的密文
- 包含認證標籤 (16 bytes)
- 每個對等節點使用獨立的會話密鑰

### 接收解密流程
1. **ServiceContainer.routeChatMessage()**:
   - 檢查是否有會話密鑰
   - 如果有密鑰且非明文，執行解密
   - 解密失敗則拒絕處理
2. **ChatViewModel.decodeChatMessage()**:
   - 使用 BinaryMessageDecoder.decode() 解析外層
   - 使用 decodeChatMessageFromBinary() 解析內層

## 🎯 格式一致性驗證

### ✅ 編碼器與解碼器匹配點
1. **MeshMessage 層**:
   - 編碼: 版本(1) + 類型(1) + ID長度(1) + ID + 數據長度(4) + 時間戳(4) + 數據
   - 解碼: 完全相同的順序和格式

2. **ChatMessage 層**:
   - 編碼: 時間戳(4) + 設備名稱長度(1) + 設備名稱 + ID長度(1) + ID + 訊息長度(2) + 訊息
   - 解碼: 完全相同的順序和格式

3. **數據類型一致性**:
   - 所有整數使用 Little Endian
   - 字符串使用 UTF-8 編碼
   - 長度欄位使用適當大小 (UInt8/UInt16/UInt32)

## 📊 性能優化特性

1. **預分配緩衝區**: 
   - `encodeOptimized()` 使用共享緩衝區減少記憶體分配

2. **批量處理**:
   - `decodeBatch()` 支持批量解碼多個訊息

3. **快速類型檢測**:
   - `detectMessageType()` 只讀取前2字節快速判斷類型

4. **安全檢查**:
   - 所有長度欄位都有上限檢查 (最大64字節)
   - 防止記憶體耗盡攻擊

## 🚨 錯誤處理

### 編碼錯誤
- `invalidMessageType`: 無效的訊息類型
- `dataTooLarge`: 數據超過限制
- `stringEncodingFailed`: UTF-8編碼失敗
- `invalidUUIDFormat`: UUID格式無效

### 解碼錯誤
- `invalidDataSize`: 數據大小無效
- `unsupportedVersion`: 協議版本不支持
- `invalidMessageType`: 訊息類型無效
- `stringDecodingFailed`: UTF-8解碼失敗
- `corruptedData`: 數據損壞

## 🔍 診斷工具

`BinaryMessageDecoder.analyzeFailedData()` 提供詳細的錯誤分析:
- 顯示數據前20字節的十六進制
- 分析協議版本和訊息類型
- 提供解碼建議

## 總結

二進制編碼器/解碼器實現了完整的格式一致性：
- ✅ 統一的協議版本和訊息類型系統
- ✅ 一致的數據編碼格式 (Little Endian)
- ✅ 完整的錯誤檢查和安全驗證
- ✅ 支持30萬用戶規模的性能優化
- ✅ 聊天訊息使用雙層編碼確保格式統一