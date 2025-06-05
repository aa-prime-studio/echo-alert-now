
import React, { useState } from 'react';
import { Wifi, WifiOff, Radio, MessageCircle, Gamepad2, Settings, Zap } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { SignalButton } from '@/components/SignalButton';
import { MessageList } from '@/components/MessageList';
import { ChatRoom } from '@/components/ChatRoom';
import { GameRoom } from '@/components/GameRoom';
import { SettingsPanel } from '@/components/SettingsPanel';
import { useSignals } from '@/hooks/useSignals';
import { toast } from 'sonner';

type TabType = 'signals' | 'chat' | 'games' | 'settings';

const SignalApp = () => {
  const { messages, connectionState, deviceName, setDeviceName, sendSignal, clearMessages } = useSignals();
  const [activeTab, setActiveTab] = useState<TabType>('signals');
  const [isConnected, setIsConnected] = useState(true);

  const handleSendSignal = async (type: 'safe' | 'supplies' | 'medical' | 'danger') => {
    await sendSignal(type);
    
    const signalNames = {
      safe: '安全訊號',
      supplies: '物資需求',
      medical: '醫療需求',
      danger: '危險警告'
    };
    
    toast.success(`${signalNames[type]}已發送`, {
      description: '訊號已廣播至附近裝置'
    });
  };

  const toggleConnection = () => {
    setIsConnected(!isConnected);
    toast.info(isConnected ? '已斷開連線' : '正在連線...', {
      description: isConnected ? '停止廣播訊號' : '開始搜尋附近裝置'
    });
  };

  const renderTabContent = () => {
    switch (activeTab) {
      case 'signals':
        return (
          <div className="flex flex-col h-full space-y-6">
            {/* Connection Status */}
            <div className={`p-3 rounded-lg text-center text-sm border ${
              isConnected 
                ? 'bg-white text-green-800 border-green-200' 
                : 'bg-white text-red-800 border-red-200'
            }`}>
              {isConnected ? '🟢 已連線 - 可發送和接收訊號' : '🔴 離線模式 - 僅能發送訊號'}
            </div>

            {/* Signal Buttons */}
            <div className="bg-white rounded-lg shadow p-6 flex-shrink-0">
              <h2 className="text-lg font-semibold text-gray-900 mb-4 text-center">
                發送應急訊號
              </h2>
              <div className="grid grid-cols-2 gap-4">
                <SignalButton
                  type="safe"
                  onSend={handleSendSignal}
                  disabled={!isConnected}
                />
                <SignalButton
                  type="supplies"
                  onSend={handleSendSignal}
                  disabled={!isConnected}
                />
                <SignalButton
                  type="medical"
                  onSend={handleSendSignal}
                  disabled={!isConnected}
                />
                <SignalButton
                  type="danger"
                  onSend={handleSendSignal}
                  disabled={!isConnected}
                />
              </div>
              <p className="text-xs text-gray-500 text-center mt-4">
                訊號會廣播至 50-500 公尺範圍內的裝置
              </p>
            </div>

            {/* Nearby Messages - 自適應高度 */}
            <div className="flex-1 min-h-0">
              <MessageList messages={messages} />
            </div>
          </div>
        );
      case 'chat':
        return <ChatRoom />;
      case 'games':
        return <GameRoom deviceName={deviceName} />;
      case 'settings':
        return (
          <SettingsPanel 
            deviceName={deviceName}
            setDeviceName={setDeviceName}
            onClearMessages={() => {
              clearMessages();
              toast.success('訊息已清除');
            }}
          />
        );
      default:
        return null;
    }
  };

  const tabConfig = [
    { id: 'signals' as TabType, label: '訊號', icon: Radio },
    { id: 'chat' as TabType, label: '聊天', icon: MessageCircle },
    { id: 'games' as TabType, label: '遊戲', icon: Gamepad2 },
    { id: 'settings' as TabType, label: '設定', icon: Settings },
  ];

  return (
    <div className="min-h-screen bg-gray-100 flex flex-col max-w-md mx-auto">
      {/* iOS Style Header */}
      <header className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
                <Zap className="w-5 h-5 text-white" />
              </div>
              <h1 className="text-xl font-bold text-gray-900">Signal-Lite</h1>
            </div>
            <Button
              variant="ghost"
              size="sm"
              onClick={toggleConnection}
              className={isConnected ? 'text-green-600' : 'text-gray-400'}
            >
              {isConnected ? <Wifi className="w-5 h-5" /> : <WifiOff className="w-5 h-5" />}
            </Button>
          </div>
        </div>
      </header>

      {/* Content Area - 自適應高度 */}
      <main className="flex-1 p-4 pb-20 min-h-0 overflow-hidden">
        {renderTabContent()}
      </main>

      {/* iOS Style Tab Bar */}
      <div className="fixed bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-md bg-white border-t border-gray-200">
        <div className="flex">
          {tabConfig.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex-1 py-2 px-1 text-center ${
                  isActive 
                    ? 'text-blue-600' 
                    : 'text-gray-400'
                }`}
              >
                <Icon className={`w-6 h-6 mx-auto mb-1 ${isActive ? 'text-blue-600' : 'text-gray-400'}`} />
                <span className={`text-xs font-medium ${isActive ? 'text-blue-600' : 'text-gray-400'}`}>
                  {tab.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Info Footer (只在訊號頁面顯示) */}
      {activeTab === 'signals' && (
        <div className="bg-blue-50 p-4 text-center space-y-1">
          <p className="text-sm text-blue-800 font-medium">
            WebRTC 概念驗證
          </p>
          <p className="text-xs text-blue-600">
            實際 iOS 版本將使用 MultipeerConnectivity 進行真正的離線通訊
          </p>
        </div>
      )}
    </div>
  );
};

export default SignalApp;
