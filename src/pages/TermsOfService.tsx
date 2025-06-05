
import React from 'react';
import { ArrowLeft, FileText, AlertTriangle, CreditCard, Users } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useNavigate } from 'react-router-dom';

const TermsOfService = () => {
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
              <FileText className="w-5 h-5 text-blue-600" />
              <h1 className="text-xl font-bold text-gray-900">使用條款</h1>
            </div>
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="max-w-4xl mx-auto px-4 py-8">
        <div className="bg-white rounded-lg shadow-sm p-8">
          <div className="prose max-w-none">
            <p className="text-sm text-gray-500 mb-6">
              最後更新：2024年6月5日
            </p>

            <section className="mb-8">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">歡迎使用 Signal-Lite</h2>
              <div className="space-y-4 text-gray-700">
                <p>這些使用條款規範您對 Signal-Lite 應用程式的使用。使用本應用程式即表示您同意這些條款。</p>
              </div>
            </section>

            <section className="mb-8">
              <div className="flex items-center space-x-2 mb-4">
                <AlertTriangle className="w-5 h-5 text-orange-600" />
                <h2 className="text-lg font-semibold text-gray-900">重要免責聲明</h2>
              </div>
              <div className="bg-orange-50 p-4 rounded-lg border border-orange-200 mb-4">
                <div className="space-y-2 text-orange-800">
                  <p><strong>Signal-Lite 是概念驗證應用程式</strong></p>
                  <p>本應用程式僅供演示和測試用途，不應用於真實的緊急情況。</p>
                </div>
              </div>
              <div className="space-y-4 text-gray-700">
                <ul className="list-disc pl-6 space-y-2">
                  <li>本應用程式不保證在真實緊急情況下的可靠性</li>
                  <li>不應作為唯一的緊急通訊手段</li>
                  <li>緊急情況請撥打當地緊急服務電話</li>
                  <li>使用風險由用戶自行承擔</li>
                </ul>
              </div>
            </section>

            <section className="mb-8">
              <div className="flex items-center space-x-2 mb-4">
                <Users className="w-5 h-5 text-blue-600" />
                <h2 className="text-lg font-semibold text-gray-900">用戶行為</h2>
              </div>
              <div className="space-y-4 text-gray-700">
                <p>使用本應用程式時，您同意：</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li>不發送虛假的緊急訊號</li>
                  <li>尊重其他用戶並保持適當的通訊內容</li>
                  <li>不濫用遊戲功能或作弊</li>
                  <li>不嘗試破解或逆向工程本應用程式</li>
                  <li>遵守當地法律法規</li>
                </ul>
              </div>
            </section>

            <section className="mb-8">
              <div className="flex items-center space-x-2 mb-4">
                <CreditCard className="w-5 h-5 text-green-600" />
                <h2 className="text-lg font-semibold text-gray-900">付費功能</h2>
              </div>
              <div className="space-y-4 text-gray-700">
                <ul className="list-disc pl-6 space-y-2">
                  <li>付費功能通過 Apple App Store 內購處理</li>
                  <li>付費後立即解鎖遊戲功能</li>
                  <li>退款政策遵循 Apple App Store 政策</li>
                  <li>可在 iOS 設定中管理訂購</li>
                </ul>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">智慧財產權</h2>
              <div className="space-y-4 text-gray-700">
                <p>Signal-Lite 及其內容受智慧財產權法保護。您獲得使用許可，但不擁有應用程式的任何權利。</p>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">責任限制</h2>
              <div className="space-y-4 text-gray-700">
                <p>在法律允許的範圍內，我們不對以下情況承擔責任：</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li>應用程式故障或中斷</li>
                  <li>數據丟失</li>
                  <li>通訊失敗</li>
                  <li>因使用本應用程式而造成的任何損失</li>
                </ul>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">條款變更</h2>
              <div className="space-y-4 text-gray-700">
                <p>我們保留隨時修改這些條款的權利。重大變更將在應用程式中通知用戶。</p>
              </div>
            </section>

            <section>
              <h2 className="text-lg font-semibold text-gray-900 mb-4">聯絡資訊</h2>
              <div className="space-y-4 text-gray-700">
                <p>如有疑問，請聯絡：</p>
                <p>電子郵件：support@signal-lite.app</p>
              </div>
            </section>
          </div>
        </div>
      </main>
    </div>
  );
};

export default TermsOfService;
