
import React from 'react';
import { ArrowLeft, Shield, Eye, Database, Globe } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useNavigate } from 'react-router-dom';

const PrivacyPolicy = () => {
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
              <Shield className="w-5 h-5 text-blue-600" />
              <h1 className="text-xl font-bold text-gray-900">隱私政策</h1>
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
              <div className="flex items-center space-x-2 mb-4">
                <Eye className="w-5 h-5 text-blue-600" />
                <h2 className="text-lg font-semibold text-gray-900">資料收集</h2>
              </div>
              <div className="space-y-4 text-gray-700">
                <p>Signal-Lite 致力於保護您的隱私。我們僅收集必要的資料來提供服務：</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li><strong>裝置名稱</strong>：用於識別您在群組中的身份</li>
                  <li><strong>訊號記錄</strong>：本地儲存您發送和接收的緊急訊號</li>
                  <li><strong>遊戲進度</strong>：本地儲存賓果遊戲的進度和分數</li>
                  <li><strong>設定偏好</strong>：本地儲存您的通知和連線設定</li>
                </ul>
                <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
                  <p className="text-blue-800 text-sm">
                    <strong>重要：</strong>所有通訊資料僅在您的裝置間直接傳輸，不會上傳到任何伺服器。
                  </p>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <div className="flex items-center space-x-2 mb-4">
                <Database className="w-5 h-5 text-blue-600" />
                <h2 className="text-lg font-semibold text-gray-900">資料儲存</h2>
              </div>
              <div className="space-y-4 text-gray-700">
                <ul className="list-disc pl-6 space-y-2">
                  <li>所有資料僅儲存在您的裝置本地</li>
                  <li>我們不會收集或儲存您的個人資料到遠端伺服器</li>
                  <li>通訊內容僅在裝置間直接傳輸</li>
                  <li>您可以隨時清除本地儲存的資料</li>
                </ul>
              </div>
            </section>

            <section className="mb-8">
              <div className="flex items-center space-x-2 mb-4">
                <Globe className="w-5 h-5 text-blue-600" />
                <h2 className="text-lg font-semibold text-gray-900">第三方服務</h2>
              </div>
              <div className="space-y-4 text-gray-700">
                <p>Signal-Lite 可能使用以下第三方服務：</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li><strong>Apple App Store</strong>：內購付費處理</li>
                  <li><strong>iOS MultipeerConnectivity</strong>：裝置間通訊</li>
                </ul>
                <p>這些服務都有各自的隱私政策，請參閱相關文件。</p>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">您的權利</h2>
              <div className="space-y-4 text-gray-700">
                <p>您有權：</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li>隨時清除應用程式中的所有資料</li>
                  <li>停用通知和其他功能</li>
                  <li>刪除應用程式及其所有資料</li>
                </ul>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">聯絡我們</h2>
              <div className="space-y-4 text-gray-700">
                <p>如果您對隱私政策有任何疑問，請聯絡我們：</p>
                <p>電子郵件：privacy@signal-lite.app</p>
              </div>
            </section>

            <section>
              <h2 className="text-lg font-semibold text-gray-900 mb-4">政策更新</h2>
              <div className="space-y-4 text-gray-700">
                <p>我們可能會不定期更新此隱私政策。重大變更將在應用程式中通知您。</p>
              </div>
            </section>
          </div>
        </div>
      </main>
    </div>
  );
};

export default PrivacyPolicy;
