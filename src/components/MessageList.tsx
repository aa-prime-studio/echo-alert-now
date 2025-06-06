import React from 'react';
import { Clock, MapPin } from 'lucide-react';
import { Message } from '@/types/language';

interface MessageListProps {
  messages: Message[];
}

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

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h3 className="font-semibold text-gray-900 text-left" style={{ fontSize: '17px' }}>附近訊號</h3>
        <span className="text-sm text-gray-500">({messages.length})</span>
      </div>
      
      <div className="space-y-4">
        {messages.length === 0 ? (
          <p className="text-gray-500 text-center">目前沒有收到任何訊號</p>
        ) : (
          messages.map((message) => (
            <div key={message.id} className="border border-gray-200 rounded-md p-4">
              <div className="flex items-center space-x-2 text-sm text-gray-500 mb-2">
                <MapPin className="w-4 h-4" />
                <span>{message.deviceName}</span>
                <Clock className="w-4 h-4" />
                <span>{formatTime(message.timestamp)}</span>
              </div>
              <p className="text-gray-800">{message.content}</p>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
