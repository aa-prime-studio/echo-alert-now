
import React from 'react';
import { AlertTriangle, Heart, Package, Shield, Clock, Users } from 'lucide-react';
import { SignalMessage } from '@/services/webrtc';
import { DirectionCompass } from '@/components/DirectionCompass';

interface MessageListProps {
  messages: SignalMessage[];
}

const signalConfig = {
  safe: { icon: Shield, color: 'text-white bg-[#263eea]', label: '我安全' },
  supplies: { icon: Package, color: 'text-white bg-[#b199ea]', label: '需要物資' },
  medical: { icon: Heart, color: 'text-white bg-[#ff5662]', label: '需要醫療' },
  danger: { icon: AlertTriangle, color: 'text-black bg-[#fec91b]', label: '危險警告' }
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
      <div className="bg-white rounded-2xl border-2 border-gray-300 h-full flex flex-col justify-center items-center p-8 text-center text-gray-500">
        <div className="w-16 h-16 bg-gray-100 rounded-xl flex items-center justify-center mb-4 border-2 border-gray-200">
          <Clock className="w-8 h-8 text-gray-400" />
        </div>
        <p className="font-bold text-black mb-2">目前沒有收到任何訊號</p>
        <p className="text-sm text-gray-600">當附近有人發送訊號時，會顯示在這裡</p>
      </div>
    );
  }

  const sortedMessages = [...messages].sort((a, b) => b.timestamp - a.timestamp);

  return (
    <div className="bg-white rounded-2xl border-2 border-gray-300 h-full flex flex-col">
      <div className="p-6 border-b-2 border-gray-200 flex-shrink-0">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 bg-yellow-400 rounded-xl flex items-center justify-center border-2 border-black">
              <Users className="w-5 h-5 text-black" />
            </div>
            <h3 className="font-bold text-black text-lg">附近訊號</h3>
            <span className="bg-gray-100 text-gray-700 px-3 py-1 rounded-full text-sm font-bold border border-gray-300">
              {messages.length}
            </span>
          </div>
          <span className="text-xs text-gray-500 font-medium">依時間排序</span>
        </div>
      </div>
      <div className="flex-1 overflow-y-auto">
        {sortedMessages.map((message) => {
          const config = signalConfig[message.type];
          const Icon = config.icon;
          
          return (
            <div key={message.id} className="p-6 border-b border-gray-200 last:border-b-0 hover:bg-gray-50 transition-colors">
              <div className="flex items-start space-x-4">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center border-2 border-black ${config.color}`}>
                  <Icon className="w-6 h-6" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-bold text-black">{config.label}</span>
                    <span className="text-sm text-gray-500 font-medium">{formatTime(message.timestamp)}</span>
                  </div>
                  
                  <div className="text-sm text-gray-600 mb-3 font-medium">來自: {message.deviceName}</div>
                  
                  {message.distance && message.direction && (
                    <DirectionCompass 
                      distance={message.distance} 
                      direction={message.direction}
                      className="mt-3"
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
