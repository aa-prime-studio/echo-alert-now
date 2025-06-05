
import React from 'react';
import { AlertTriangle, Heart, Package, Shield, Clock, Users } from 'lucide-react';
import { SignalMessage } from '@/services/webrtc';
import { DirectionCompass } from '@/components/DirectionCompass';

interface MessageListProps {
  messages: SignalMessage[];
}

const signalConfig = {
  safe: { icon: Shield, color: 'text-green-600 bg-green-50', label: '我安全' },
  supplies: { icon: Package, color: 'text-yellow-600 bg-yellow-50', label: '需要物資' },
  medical: { icon: Heart, color: 'text-red-600 bg-red-50', label: '需要醫療' },
  danger: { icon: AlertTriangle, color: 'text-gray-900 bg-gray-50', label: '危險警告' }
};

export const MessageList: React.FC<MessageListProps> = ({ messages }) => {
  const formatTime = (timestamp: number) => {
    const now = Date.now();
    const diff = now - timestamp;
    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(diff / (1000 * 60 * 60));
    
    if (hours > 0) {
      return `${hours}小時前`;
    } else if (minutes > 0) {
      return `${minutes}分鐘前`;
    } else {
      return '剛剛';
    }
  };

  if (messages.length === 0) {
    return (
      <div className="bg-white rounded-lg shadow h-full flex flex-col justify-center items-center p-6 text-center text-gray-500">
        <Clock className="w-12 h-12 mx-auto mb-4 opacity-50" />
        <p>目前沒有收到任何訊號</p>
        <p className="text-sm mt-2">當附近有人發送訊號時，會顯示在這裡</p>
      </div>
    );
  }

  // 按距離排序（近的優先）
  const sortedMessages = [...messages].sort((a, b) => {
    if (!a.distance && !b.distance) return b.timestamp - a.timestamp;
    if (!a.distance) return 1;
    if (!b.distance) return -1;
    return a.distance - b.distance;
  });

  return (
    <div className="bg-white rounded-lg shadow h-full flex flex-col">
      <div className="p-4 border-b flex-shrink-0">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Users className="w-5 h-5 text-blue-600" />
            <h3 className="font-semibold text-gray-900">附近訊號</h3>
            <span className="text-sm text-gray-500">({messages.length})</span>
          </div>
          <span className="text-xs text-gray-500">依距離排序</span>
        </div>
      </div>
      <div className="flex-1 overflow-y-auto">
        {sortedMessages.map((message) => {
          const config = signalConfig[message.type];
          const Icon = config.icon;
          
          return (
            <div key={message.id} className="p-4 border-b last:border-b-0 hover:bg-gray-50">
              <div className="flex items-start space-x-3">
                <div className={`w-10 h-10 rounded-full flex items-center justify-center ${config.color}`}>
                  <Icon className="w-5 h-5" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between mb-1">
                    <span className="font-medium text-gray-900">{config.label}</span>
                    <span className="text-sm text-gray-500">{formatTime(message.timestamp)}</span>
                  </div>
                  
                  <div className="text-sm text-gray-600 mb-2">來自: {message.deviceName}</div>
                  
                  {message.distance && message.direction && (
                    <DirectionCompass 
                      distance={message.distance} 
                      direction={message.direction}
                      className="mt-2"
                    />
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
