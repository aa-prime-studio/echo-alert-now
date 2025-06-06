
import React from 'react';
import { AlertTriangle, Heart, Package, Shield, Clock } from 'lucide-react';
import { SignalMessage } from '@/services/webrtc';
import { DirectionCompass } from '@/components/DirectionCompass';
import { Separator } from '@/components/ui/separator';

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
      <div className="flex flex-col justify-center items-center p-8 text-center text-gray-500 border border-black rounded-lg bg-gray-50">
        <p className="text-gray-600 mb-2">目前沒有訊息</p>
        <p className="text-sm text-gray-400">當附近有人發送訊號時，會顯示在這裡</p>
      </div>
    );
  };

  // 按時間排序（最新的在上方）
  const sortedMessages = [...messages].sort((a, b) => b.timestamp - a.timestamp);

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-sm font-semibold text-gray-900 text-left">附近訊號</h3>
        <span className="text-sm text-gray-500">({messages.length})</span>
      </div>
      
      <div className="space-y-0">
        {sortedMessages.map((message, index) => {
          const config = signalConfig[message.type];
          const Icon = config.icon;
          const isLastMessage = index === sortedMessages.length - 1;
          
          return (
            <React.Fragment key={message.id}>
              <div className="flex items-start space-x-3 p-4 bg-white">
                <div className={`w-10 h-10 rounded-full flex items-center justify-center ${config.color} flex-shrink-0 border border-black`}>
                  <Icon className="w-5 h-5" />
                </div>
                <div className="flex-1 min-w-0 relative">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <span className="font-medium text-gray-900">{config.label}</span>
                      <div className="text-sm text-gray-600 mb-1 mt-1">來自: {message.deviceName}</div>
                      <div className="text-sm text-gray-500">{formatTime(message.timestamp)}</div>
                    </div>
                    
                    {message.distance && message.direction && (
                      <div className="ml-4">
                        <DirectionCompass 
                          distance={message.distance} 
                          direction={message.direction}
                        />
                      </div>
                    )}
                  </div>
                </div>
              </div>
              {!isLastMessage && (
                <Separator className="bg-black" />
              )}
            </React.Fragment>
          );
        })}
      </div>
    </div>
  );
};
