
import React from 'react';
import { ArrowLeft, HelpCircle, Smartphone, Wifi, MessageCircle, Gamepad2, Settings, AlertTriangle, Heart, Package, Shield, Zap } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useNavigate } from 'react-router-dom';

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
        <div className="space-y-8">
          {/* 快速開始 */}
          <div className="bg-white rounded-lg shadow-sm p-6">
            <div className="flex items-center space-x-2 mb-4">
              <Zap className="w-5 h-5 text-blue-600" />
              <h2 className="text-lg font-semibold text-gray-900">快速開始</h2>
            </div>
            <div className="space-y-4 text-gray-700">
              <p>Signal-Lite 是一個概念驗證的離線緊急通訊應用程式。</p>
              <ol className="list-decimal pl-6 space-y-2">
                <li>開啟應用程式後，系統會自動搜尋附近的裝置</li>
                <li>在「訊號」分頁中發送你的狀態訊號</li>
                <li>在「聊天」分頁中與附近的人即時對話</li>
                <li>在「遊戲」分頁中參與賓果遊戲（需付費解鎖）</li>
                <li>在「設定」分頁中調整個人設定</li>
              </ol>
            </div>
          </div>

          {/* 訊號類型說明 */}
          <div className="bg-white rounded-lg shadow-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">訊號類型說明</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="flex items-center space-x-3 p-3 border rounded-lg">
                <div className="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center">
                  <Shield className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 className="font-medium">我安全</h3>
                  <p className="text-sm text-gray-600">告知周圍人員你目前安全無虞</p>
                </div>
              </div>
              
              <div className="flex items-center space-x-3 p-3 border rounded-lg">
                <div className="w-10 h-10 bg-yellow-500 rounded-full flex items-center justify-center">
                  <Package className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 className="font-medium">需要物資</h3>
                  <p className="text-sm text-gray-600">需要食物、水或其他基本物資</p>
                </div>
              </div>
              
              <div className="flex items-center space-x-3 p-3 border rounded-lg">
                <div className="w-10 h-10 bg-red-500 rounded-full flex items-center justify-center">
                  <Heart className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 className="font-medium">需要醫療</h3>
                  <p className="text-sm text-gray-600">需要醫療協助或緊急救護</p>
                </div>
              </div>
              
              <div className="flex items-center space-x-3 p-3 border rounded-lg">
                <div className="w-10 h-10 bg-gray-900 rounded-full flex items-center justify-center">
                  <AlertTriangle className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 className="font-medium">危險警告</h3>
                  <p className="text-sm text-gray-600">警告周圍存在危險狀況</p>
                </div>
              </div>
            </div>
          </div>

          {/* 功能說明 */}
          <div className="bg-white rounded-lg shadow-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">功能說明</h2>
            <div className="space-y-6">
              <div className="flex items-start space-x-3">
                <Smartphone className="w-6 h-6 text-blue-600 mt-1" />
                <div>
                  <h3 className="font-medium mb-2">訊號廣播</h3>
                  <p className="text-gray-600 text-sm">點擊訊號按鈕會將你的狀態廣播給 50-500 公尺範圍內的其他裝置。每次發送都會包含時間戳和模糊化的距離方向資訊。</p>
                </div>
              </div>
              
              <div className="flex items-start space-x-3">
                <MessageCircle className="w-6 h-6 text-blue-600 mt-1" />
                <div>
                  <h3 className="font-medium mb-2">即時聊天</h3>
                  <p className="text-gray-600 text-sm">與附近連接的裝置進行即時文字對話。所有訊息都是點對點傳輸，不會儲存在任何伺服器上。</p>
                </div>
              </div>
              
              <div className="flex items-start space-x-3">
                <Gamepad2 className="w-6 h-6 text-blue-600 mt-1" />
                <div>
                  <h3 className="font-medium mb-2">賓果遊戲（付費功能）</h3>
                  <p className="text-gray-600 text-sm">與附近的人一起玩賓果遊戲，可以在緊急情況下提供娛樂和社交互動。升級到付費版本即可解鎖。</p>
                </div>
              </div>
              
              <div className="flex items-start space-x-3">
                <Settings className="w-6 h-6 text-blue-600 mt-1" />
                <div>
                  <h3 className="font-medium mb-2">個人設定</h3>
                  <p className="text-gray-600 text-sm">調整裝置名稱、通知偏好、連線設定等。裝置名稱只能修改一次，請謹慎選擇。</p>
                </div>
              </div>
            </div>
          </div>

          {/* 重要提醒 */}
          <div className="bg-orange-50 border border-orange-200 rounded-lg p-6">
            <div className="flex items-start space-x-3">
              <AlertTriangle className="w-6 h-6 text-orange-600 mt-1" />
              <div>
                <h2 className="text-lg font-semibold text-orange-900 mb-2">重要提醒</h2>
                <ul className="list-disc pl-6 space-y-2 text-orange-800">
                  <li>這是概念驗證版本，不應用於真實緊急情況</li>
                  <li>實際 iOS 版本將使用 MultipeerConnectivity 進行真正的離線通訊</li>
                  <li>緊急情況請撥打當地緊急服務電話</li>
                  <li>所有通訊資料僅在裝置間直接傳輸，不會上傳到伺服器</li>
                </ul>
              </div>
            </div>
          </div>

          {/* 技術資訊 */}
          <div className="bg-white rounded-lg shadow-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">技術資訊</h2>
            <div className="space-y-4 text-gray-700">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <h3 className="font-medium mb-2">Web 版本（目前）</h3>
                  <ul className="text-sm space-y-1">
                    <li>• 使用 WebRTC 模擬離線通訊</li>
                    <li>• 概念驗證和功能展示</li>
                    <li>• 模擬附近裝置和訊號</li>
                  </ul>
                </div>
                <div>
                  <h3 className="font-medium mb-2">iOS 版本（規劃）</h3>
                  <ul className="text-sm space-y-1">
                    <li>• 使用 MultipeerConnectivity</li>
                    <li>• 真正的離線通訊</li>
                    <li>• 藍牙和 Wi-Fi Direct 支援</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>

          {/* 聯絡資訊 */}
          <div className="bg-white rounded-lg shadow-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">需要幫助？</h2>
            <div className="space-y-4 text-gray-700">
              <p>如果您在使用過程中遇到問題，請聯絡我們：</p>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <h3 className="font-medium">技術支援</h3>
                  <p className="text-sm">support@signal-lite.app</p>
                </div>
                <div>
                  <h3 className="font-medium">隱私問題</h3>
                  <p className="text-sm">privacy@signal-lite.app</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};

export default Help;
