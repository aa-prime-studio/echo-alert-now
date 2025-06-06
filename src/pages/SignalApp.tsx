
import React, { useState } from 'react';
import { Wifi, WifiOff, Radio, MessageCircle, Gamepad2, Settings } from 'lucide-react';
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
        return { bg: '#e5d804', title: 'Broadcast\nSignal', subtitle: null };
      case 'chat':
        return { bg: '#ab93e5', title: 'Live Support\nChatroom', subtitle: null };
      case 'games':
        return { bg: '#283ee5', title: 'Bingo Game\nRoom', subtitle: null };
      case 'settings':
        return { bg: '#00d76a', title: 'Settings', subtitle: null };
      default:
        return { bg: '#e5d804', title: 'Broadcast\nSignal', subtitle: null };
    }
  };

  const headerConfig = getHeaderConfig();

  const renderTabContent = () => {
    switch (activeTab) {
      case 'signals':
        return (
          <div className="space-y-6">
            <div>
              <h2 className="text-lg font-semibold text-gray-900 mb-4 text-left">發送訊息</h2>
              <div className="flex gap-3 mb-4">
                <div className="w-1/2">
                  <SignalButton
                    type="safe"
                    onSend={handleSendSignal}
                    disabled={!isConnected}
                    size="large"
                  />
                </div>
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
        return (
          <div className="space-y-6">
            <div>
              <h2 className="text-lg font-semibold text-gray-900 mb-4 text-left">發送訊息</h2>
              <div className="flex gap-3 mb-4">
                <div className="w-1/2">
                  <SignalButton
                    type="safe"
                    onSend={handleSendSignal}
                    disabled={!isConnected}
                    size="large"
                  />
                </div>
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
            <div className="flex-1">
              <MessageList messages={messages} />
            </div>
          </div>
        );
    }
  };

  const tabConfig = [
    { id: 'signals' as TabType, label: '訊號', icon: Radio },
    { id: 'chat' as TabType, label: '聊天室', icon: MessageCircle },
    { id: 'games' as TabType, label: '遊戲', icon: Gamepad2 },
    { id: 'settings' as TabType, label: '設定', icon: Settings },
  ];

  return (
    <div className="flex flex-col h-screen max-w-md mx-auto bg-gray-100">
      {/* Header */}
      <header className="text-black px-4 py-6 flex-shrink-0" style={{ backgroundColor: headerConfig.bg }}>
        <div className="flex items-center justify-between mb-2">
          <div className="flex-1">
            {activeTab === 'signals' && (
              <div className="flex items-center mb-2">
                <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                <p className="text-sm opacity-80">已連線 - 可發送和接收訊號</p>
              </div>
            )}
            <h1 className="text-5xl font-bold whitespace-pre-line">{headerConfig.title}</h1>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={toggleConnection}
            className="text-black hover:bg-black/10"
          >
            {isConnected ? <Wifi className="w-5 h-5" /> : <WifiOff className="w-5 h-5" />}
          </Button>
        </div>
      </header>

      {/* Content */}
      <main className="flex-1 bg-white rounded-t-3xl -mt-4 p-6 pb-20 relative z-10 overflow-auto">
        {renderTabContent()}
      </main>

      {/* Bottom Navigation - Fixed at bottom */}
      <nav className="fixed bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-md bg-white border-t border-gray-200 shadow-lg px-4 py-2 z-50">
        <div className="flex justify-around items-center">
          {tabConfig.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className="flex flex-col items-center space-y-1 py-2 min-w-0 flex-1"
              >
                <div className={`w-10 h-10 rounded-full flex items-center justify-center transition-all duration-200 ${
                  isActive 
                    ? 'text-white' 
                    : 'bg-gray-100 text-gray-400 hover:bg-gray-200'
                }`} style={{ backgroundColor: isActive ? '#283ee5' : undefined }}>
                  <Icon className="w-5 h-5" style={{ color: isActive ? '#02d35c' : undefined }} />
                </div>
                <span className={`text-xs font-medium ${
                  isActive ? 'text-blue-600' : 'text-gray-400'
                }`}>
                  {tab.label}
                </span>
              </button>
            );
          })}
        </div>
      </nav>
    </div>
  );
};

export default SignalApp;
