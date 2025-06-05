
import React from 'react';
import { ArrowLeft, HelpCircle, Radio, MessageCircle, Gamepad2, Settings, Zap, Users, Shield, Crown } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useNavigate } from 'react-router-dom';
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from '@/components/ui/accordion';

const Help = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 py-3">
          <div className="flex items-center space-x-3">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => navigate(-1)}
              className="text-blue-600"
            >
              <ArrowLeft className="w-4 h-4 mr-1" />
              返回
            </Button>
            <div className="flex items-center space-x-2">
              <HelpCircle className="w-5 h-5 text-blue-600" />
              <h1 className="text-xl font-bold text-gray-900">幫助與說明</h1>
            </div>
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="max-w-4xl mx-auto px-4 py-8">
        <div className="bg-white rounded-lg shadow-sm p-8">
          <div className="space-y-6">
            {/* 應用程式簡介 */}
            <section>
              <div className="flex items-center space-x-2 mb-4">
                <Zap className="w-5 h-5 text-blue-600" />
                <h2 className="text-xl font-semibold text-gray-900">Signal-Lite 簡介</h2>
              </div>
              <div className="bg-blue-50 p-4 rounded-lg border border-blue-200 mb-4">
                <p className="text-blue-800">
                  Signal-Lite 是一個緊急通訊和社交遊戲的概念驗證應用程式，展示了離線通訊的可能性。
                </p>
              </div>
            </section>

            {/* 功能說明 */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-4">功能說明</h2>
              <Accordion type="single" collapsible className="w-full">
                
                <AccordionItem value="signals">
                  <AccordionTrigger className="flex items-center">
                    <div className="flex items-center space-x-2">
                      <Radio className="w-4 h-4 text-blue-600" />
                      <span>訊號功能</span>
                    </div>
                  </AccordionTrigger>
                  <AccordionContent className="space-y-3">
                    <p className="text-gray-700">發送和接收緊急訊號，與附近的裝置通訊。</p>
                    <div className="grid grid-cols-2 gap-4">
                      <div className="p-3 bg-green-50 rounded-lg border border-green-200">
                        <div className="text-green-800 font-medium">🟢 安全訊號</div>
                        <div className="text-sm text-green-600">告知其他人您的安全狀況</div>
                      </div>
                      <div className="p-3 bg-blue-50 rounded-lg border border-blue-200">
                        <div className="text-blue-800 font-medium">📦 物資需求</div>
                        <div className="text-sm text-blue-600">請求食物、水或其他物資</div>
                      </div>
                      <div className="p-3 bg-red-50 rounded-lg border border-red-200">
                        <div className="text-red-800 font-medium">🏥 醫療需求</div>
                        <div className="text-sm text-red-600">請求醫療協助</div>
                      </div>
                      <div className="p-3 bg-orange-50 rounded-lg border border-orange-200">
                        <div className="text-orange-800 font-medium">⚠️ 危險警告</div>
                        <div className="text-sm text-orange-600">警告其他人注意危險</div>
                      </div>
                    </div>
                    <p className="text-sm text-gray-600">
                      <strong>使用方式：</strong>點擊對應的訊號按鈕即可發送，訊號會廣播至 50-500 公尺範圍內的裝置。
                    </p>
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="chat">
                  <AccordionTrigger className="flex items-center">
                    <div className="flex items-center space-x-2">
                      <MessageCircle className="w-4 h-4 text-blue-600" />
                      <span>聊天功能</span>
                    </div>
                  </AccordionTrigger>
                  <AccordionContent className="space-y-3">
                    <p className="text-gray-700">與附近的用戶進行即時文字聊天。</p>
                    <ul className="list-disc pl-6 space-y-1 text-gray-600">
                      <li>發送文字訊息</li>
                      <li>查看誰在線上</li>
                      <li>群組聊天功能</li>
                    </ul>
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="games">
                  <AccordionTrigger className="flex items-center">
                    <div className="flex items-center space-x-2">
                      <Gamepad2 className="w-4 h-4 text-blue-600" />
                      <span>遊戲功能</span>
                    </div>
                  </AccordionTrigger>
                  <AccordionContent className="space-y-3">
                    <p className="text-gray-700">多人賓果遊戲，與其他玩家一起娛樂。</p>
                    <div className="bg-yellow-50 p-3 rounded-lg border border-yellow-200">
                      <div className="flex items-center space-x-2 mb-2">
                        <Crown className="w-4 h-4 text-yellow-600" />
                        <span className="text-yellow-800 font-medium">付費功能</span>
                      </div>
                      <p className="text-sm text-yellow-700">
                        需要升級到付費版才能使用完整的遊戲功能。
                      </p>
                    </div>
                    <ul className="list-disc pl-6 space-y-1 text-gray-600">
                      <li>創建或加入遊戲房間</li>
                      <li>自動生成賓果卡片</li>
                      <li>即時同步遊戲進度</li>
                      <li>排行榜和計分系統</li>
                    </ul>
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="settings">
                  <AccordionTrigger className="flex items-center">
                    <div className="flex items-center space-x-2">
                      <Settings className="w-4 h-4 text-blue-600" />
                      <span>設定功能</span>
                    </div>
                  </AccordionTrigger>
                  <AccordionContent className="space-y-3">
                    <p className="text-gray-700">自訂應用程式設定和管理帳戶。</p>
                    <ul className="list-disc pl-6 space-y-1 text-gray-600">
                      <li><strong>裝置名稱：</strong>設定在群組中顯示的名稱（可修改1次）</li>
                      <li><strong>通知設定：</strong>開啟或關閉推播通知</li>
                      <li><strong>隱私設定：</strong>管理位置分享和自動連線</li>
                      <li><strong>訂購管理：</strong>查看付費狀態和管理訂購</li>
                      <li><strong>資料管理：</strong>清除訊息或刪除帳號</li>
                    </ul>
                  </AccordionContent>
                </AccordionItem>

              </Accordion>
            </section>

            {/* 常見問題 */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-4">常見問題</h2>
              <Accordion type="single" collapsible className="w-full">
                
                <AccordionItem value="faq1">
                  <AccordionTrigger>這個應用程式真的可以離線使用嗎？</AccordionTrigger>
                  <AccordionContent>
                    <p className="text-gray-700">
                      目前的網頁版本是概念驗證，使用 WebRTC 技術。真正的 iOS 版本將使用 Apple 的 MultipeerConnectivity 框架，
                      可以在沒有網路的情況下通過 Wi-Fi 和藍牙進行裝置間直接通訊。
                    </p>
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="faq2">
                  <AccordionTrigger>通訊範圍有多遠？</AccordionTrigger>
                  <AccordionContent>
                    <p className="text-gray-700">
                      實際的 MultipeerConnectivity 版本中，Wi-Fi 直連可達約 50-100 公尺，
                      藍牙約 10-30 公尺。具體範圍取決於環境和裝置性能。
                    </p>
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="faq3">
                  <AccordionTrigger>為什麼需要付費才能玩遊戲？</AccordionTrigger>
                  <AccordionContent>
                    <p className="text-gray-700">
                      緊急通訊功能完全免費。遊戲功能作為額外的娛樂內容需要付費解鎖，
                      這有助於支持應用程式的開發和維護。
                    </p>
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="faq4">
                  <AccordionTrigger>我的資料安全嗎？</AccordionTrigger>
                  <AccordionContent>
                    <p className="text-gray-700">
                      是的。所有通訊都是裝置間直接傳輸，不經過任何伺服器。
                      應用程式只在本地儲存必要的設定資料，不會上傳您的個人資訊。
                    </p>
                  </AccordionContent>
                </AccordionItem>

                <AccordionItem value="faq5">
                  <AccordionTrigger>可以用於真實的緊急情況嗎？</AccordionTrigger>
                  <AccordionContent>
                    <div className="space-y-3">
                      <div className="bg-red-50 p-3 rounded-lg border border-red-200">
                        <p className="text-red-800 font-medium">
                          ⚠️ 重要：本應用程式目前僅供概念驗證和測試用途
                        </p>
                      </div>
                      <p className="text-gray-700">
                        真實緊急情況請撥打當地緊急服務電話（如 119、110）。
                        本應用程式不保證在緊急情況下的可靠性。
                      </p>
                    </div>
                  </AccordionContent>
                </AccordionItem>

              </Accordion>
            </section>

            {/* 技術說明 */}
            <section>
              <div className="flex items-center space-x-2 mb-4">
                <Shield className="w-5 h-5 text-blue-600" />
                <h2 className="text-xl font-semibold text-gray-900">技術說明</h2>
              </div>
              <div className="bg-gray-50 p-4 rounded-lg">
                <p className="text-gray-700 mb-3">
                  <strong>目前版本：</strong>網頁概念驗證，使用 WebRTC 技術
                </p>
                <p className="text-gray-700">
                  <strong>計劃版本：</strong>原生 iOS 應用程式，使用 MultipeerConnectivity 實現真正的離線通訊
                </p>
              </div>
            </section>

            {/* 聯絡資訊 */}
            <section>
              <div className="flex items-center space-x-2 mb-4">
                <Users className="w-5 h-5 text-blue-600" />
                <h2 className="text-xl font-semibold text-gray-900">需要更多幫助？</h2>
              </div>
              <div className="space-y-2 text-gray-700">
                <p>如果您有其他問題或建議，歡迎聯絡我們：</p>
                <p>📧 電子郵件：support@signal-lite.app</p>
                <p>📄 更多資訊請查看 <Button variant="link" className="p-0 h-auto text-blue-600" onClick={() => navigate('/privacy')}>隱私政策</Button> 和 <Button variant="link" className="p-0 h-auto text-blue-600" onClick={() => navigate('/terms')}>使用條款</Button></p>
              </div>
            </section>
          </div>
        </div>
      </main>
    </div>
  );
};

export default Help;
