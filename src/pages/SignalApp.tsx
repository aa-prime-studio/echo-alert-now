
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
            <div className={`p-4 rounded-2xl text-center border-2 ${
              isConnected 
                ? 'bg-white border-gray-300 text-gray-700' 
                : 'bg-white border-gray-300 text-gray-700'
            }`}>
              <div className="flex items-center justify-center space-x-2">
                <div className={`w-3 h-3 rounded-full ${isConnected ? 'bg-green-500' : 'bg-red-500'}`}></div>
                <span className="font-medium">
                  {isConnected ? '已連線 - 可發送和接收訊號' : '離線模式 - 僅能發送訊號'}
                </span>
              </div>
            </div>

            {/* Signal Buttons */}
            <div className="bg-white rounded-2xl border-2 border-gray-300 p-6 flex-shrink-0">
              <h2 className="text-xl font-bold text-black mb-6 text-center">
                發送訊號
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
              <p className="text-xs text-gray-600 text-center mt-4 font-medium">
                訊號會廣播至 50-500 公尺範圍內的裝置
              </p>
            </div>

            {/* Nearby Messages */}
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
      {/* Modern Header */}
      <header className="bg-white border-b-2 border-gray-300 sticky top-0 z-10">
        <div className="px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-yellow-400 rounded-xl flex items-center justify-center border-2 border-black">
                <Zap className="w-6 h-6 text-black" />
              </div>
              <h1 className="text-xl font-bold text-black">Signal-Lite</h1>
            </div>
            <Button
              variant="ghost"
              size="sm"
              onClick={toggleConnection}
              className={`rounded-full border-2 ${
                isConnected 
                  ? 'text-green-600 border-green-200 hover:bg-green-50' 
                  : 'text-gray-400 border-gray-200 hover:bg-gray-50'
              }`}
            >
              {isConnected ? <Wifi className="w-5 h-5" /> : <WifiOff className="w-5 h-5" />}
            </Button>
          </div>
        </div>
      </header>

      {/* Content Area */}
      <main className="flex-1 p-6 pb-24 min-h-0 overflow-hidden">
        {renderTabContent()}
      </main>

      {/* Modern Tab Bar */}
      <div className="fixed bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-md bg-white border-t-2 border-gray-300">
        <div className="flex px-2 py-3">
          {tabConfig.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex-1 py-3 px-2 text-center rounded-xl mx-1 transition-all duration-200 ${
                  isActive 
                    ? 'bg-yellow-400 text-black border-2 border-black shadow-sm' 
                    : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
                }`}
              >
                <Icon className={`w-6 h-6 mx-auto mb-1 ${isActive ? 'text-black' : 'text-gray-500'}`} />
                <span className={`text-xs font-bold ${isActive ? 'text-black' : 'text-gray-500'}`}>
                  {tab.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Info Footer */}
      {activeTab === 'signals' && (
        <div className="bg-white border-t-2 border-gray-300 p-4 text-center space-y-2">
          <p className="text-sm text-black font-bold">
            WebRTC 概念驗證
          </p>
          <p className="text-xs text-gray-600">
            實際 iOS 版本將使用 MultipeerConnectivity 進行真正的離線通訊
          </p>
        </div>
      )}
    </div>
  );
};

export default SignalApp;
