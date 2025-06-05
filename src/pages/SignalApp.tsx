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

  const getHeaderConfig = () => {
    switch (activeTab) {
      case 'signals':
        return { bg: 'bg-yellow-400', title: 'Broadcast Signal', subtitle: '已連線 - 可發送和接收訊號' };
      case 'chat':
        return { bg: 'bg-purple-400', title: 'Live Support Chatroom', subtitle: '即時聊天室' };
      case 'games':
        return { bg: 'bg-blue-500', title: 'Bingo Game Room', subtitle: '線上遊戲房間' };
      case 'settings':
        return { bg: 'bg-green-400', title: 'Settings', subtitle: '應用程式設定' };
    }
  };

  const headerConfig = getHeaderConfig();

  const renderTabContent = () => {
    switch (activeTab) {
      case 'signals':
        return (
          <div className="space-y-6">
            {/* Signal Buttons */}
            <div>
              <h2 className="text-lg font-semibold text-gray-900 mb-4">發送訊號</h2>
              <div className="flex gap-3 mb-4">
                {/* Safe button takes half width */}
                <div className="w-1/2">
                  <SignalButton
                    type="safe"
                    onSend={handleSendSignal}
                    disabled={!isConnected}
                    size="large"
                  />
                </div>
                
                {/* Other three buttons in vertical stack on the right */}
                <div className="w-1/2 flex flex-col gap-3">
                  <SignalButton
                    type="supplies"
                    onSend={handleSendSignal}
                    disabled={!isConnected}
                    size="small"
                  />
                  <SignalButton
                    type="medical"
                    onSend={handleSendSignal}
                    disabled={!isConnected}
                    size="small"
                  />
                  <SignalButton
                    type="danger"
                    onSend={handleSendSignal}
                    disabled={!isConnected}
                    size="small"
                  />
                </div>
              </div>
              <p className="text-xs text-gray-500 text-center">
                訊號會廣播至 50-500 公尺範圍內的裝置
              </p>
            </div>

            {/* Nearby Messages */}
            <div className="flex-1">
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
    { id: 'chat' as TabType, label: '聊天室', icon: MessageCircle },
    { id: 'games' as TabType, label: '遊戲', icon: Gamepad2 },
    { id: 'settings' as TabType, label: '設定', icon: Settings },
  ];

  return (
    <div className="min-h-screen bg-gray-100 flex flex-col max-w-md mx-auto">
      {/* Colored Header */}
      <header className={`${headerConfig.bg} text-black px-4 py-6`}>
        <div className="flex items-center justify-between mb-2">
          <h1 className="text-5xl font-bold">{headerConfig.title}</h1>
          <Button
            variant="ghost"
            size="sm"
            onClick={toggleConnection}
            className="text-black hover:bg-black/10"
          >
            {isConnected ? <Wifi className="w-5 h-5" /> : <WifiOff className="w-5 h-5" />}
          </Button>
        </div>
        <div className="flex items-center">
          <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
          <p className="text-sm opacity-80">{headerConfig.subtitle}</p>
        </div>
      </header>

      {/* White Content Card */}
      <main className="flex-1 bg-white rounded-t-3xl -mt-4 p-6 pb-32 relative z-10">
        {renderTabContent()}
      </main>

      {/* Bottom Navigation - Circular design like in the image */}
      <div className="fixed bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-md bg-white border-t border-gray-200 px-4 py-4">
        <div className="flex justify-around items-center">
          {tabConfig.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className="flex flex-col items-center space-y-2"
              >
                <div className={`w-12 h-12 rounded-full flex items-center justify-center transition-all duration-200 ${
                  isActive 
                    ? 'bg-blue-500 text-white' 
                    : 'bg-gray-100 text-gray-400 hover:bg-gray-200'
                }`}>
                  <Icon className="w-6 h-6" />
                </div>
                <span className={`text-xs font-medium ${
                  isActive ? 'text-blue-500' : 'text-gray-400'
                }`}>
                  {tab.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default SignalApp;
