
import React, { useState } from 'react';
import { Wifi, WifiOff, Settings, Trash2, Zap } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { SignalButton } from '@/components/SignalButton';
import { MessageList } from '@/components/MessageList';
import { useSignals } from '@/hooks/useSignals';
import { toast } from 'sonner';

const SignalApp = () => {
  const { messages, connectionState, deviceName, setDeviceName, sendSignal, clearMessages } = useSignals();
  const [isConnected, setIsConnected] = useState(true);
  const [showSettings, setShowSettings] = useState(false);

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

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <header className="bg-white shadow-sm sticky top-0 z-10">
        <div className="max-w-md mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
                <Zap className="w-5 h-5 text-white" />
              </div>
              <h1 className="text-xl font-bold text-gray-900">Signal-Lite</h1>
            </div>
            <div className="flex items-center space-x-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={toggleConnection}
                className={isConnected ? 'text-green-600' : 'text-gray-400'}
              >
                {isConnected ? <Wifi className="w-5 h-5" /> : <WifiOff className="w-5 h-5" />}
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setShowSettings(!showSettings)}
              >
                <Settings className="w-5 h-5" />
              </Button>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-md mx-auto p-4 space-y-6">
        {/* Connection Status */}
        <div className={`p-3 rounded-lg text-center text-sm ${
          isConnected 
            ? 'bg-green-100 text-green-800' 
            : 'bg-red-100 text-red-800'
        }`}>
          {isConnected ? '🟢 已連線 - 可發送和接收訊號' : '🔴 離線模式 - 僅能發送訊號'}
        </div>

        {/* Settings Panel */}
        {showSettings && (
          <div className="bg-white rounded-lg shadow p-4 space-y-4">
            <h3 className="font-semibold text-gray-900">設定</h3>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                裝置名稱
              </label>
              <input
                type="text"
                value={deviceName}
                onChange={(e) => setDeviceName(e.target.value)}
                className="w-full p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                maxLength={16}
              />
            </div>
            <div className="flex items-center justify-between pt-2">
              <span className="text-sm text-gray-600">清除所有訊息</span>
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  clearMessages();
                  toast.success('訊息已清除');
                }}
                className="text-red-600 hover:text-red-700"
              >
                <Trash2 className="w-4 h-4" />
              </Button>
            </div>
          </div>
        )}

        {/* Signal Buttons */}
        <div className="bg-white rounded-lg shadow p-6">
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
            訊號會廣播至 50-100 公尺範圍內的裝置
          </p>
        </div>

        {/* Message List */}
        <MessageList messages={messages} />

        {/* Info */}
        <div className="bg-blue-50 rounded-lg p-4 text-center">
          <p className="text-sm text-blue-800">
            <strong>WebRTC 概念驗證</strong>
          </p>
          <p className="text-xs text-blue-600 mt-1">
            實際 iOS 版本將使用 MultipeerConnectivity 進行真正的離線通訊
          </p>
        </div>
      </div>
    </div>
  );
};

export default SignalApp;
