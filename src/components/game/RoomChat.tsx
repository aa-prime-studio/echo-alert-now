
import React, { useEffect, useRef } from 'react';
import { Send } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { RoomChatMessage } from '@/types/game';

interface RoomChatProps {
  roomName: string;
  messages: RoomChatMessage[];
  newMessage: string;
  setNewMessage: (message: string) => void;
  onSendMessage: () => void;
}

export const RoomChat: React.FC<RoomChatProps> = ({
  roomName,
  messages,
  newMessage,
  setNewMessage,
  onSendMessage
}) => {
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const formatChatTime = (timestamp: number) => {
    const now = Date.now();
    const diff = now - timestamp;
    const minutes = Math.floor(diff / (1000 * 60));
    
    if (minutes > 0) {
      return `${minutes}分鐘前`;
    } else {
      return '剛剛';
    }
  };

  return (
    <div className="flex-1 bg-gray-50 rounded-lg flex flex-col min-h-0">
      <div className="p-3 border-b border-gray-200">
        <h4 className="text-sm font-medium text-gray-900">房間聊天</h4>
      </div>
      
      {/* 聊天訊息 */}
      <div className="flex-1 overflow-y-auto p-3 space-y-2">
        {messages.length === 0 ? (
          <div className="text-center text-gray-500 py-4">
            <p className="text-sm">歡迎來到 {roomName}</p>
            <p className="text-xs mt-1">開始聊天為遊戲加油吧！</p>
          </div>
        ) : (
          // 反轉陣列順序，讓最新訊息顯示在底部
          [...messages].reverse().map((msg) => (
            <div key={msg.id} className={`flex ${msg.isOwn ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-xs px-3 py-2 rounded-lg ${
                msg.isOwn 
                  ? 'bg-blue-500 text-white' 
                  : 'bg-white text-gray-900 border'
              }`}>
                <div className="flex items-center space-x-2 mb-1">
                  <span className={`font-medium text-xs ${
                    msg.isOwn ? 'text-blue-100' : 'text-gray-600'
                  }`}>
                    {msg.isOwn ? '我' : msg.playerName}
                  </span>
                  <span className={`text-xs ${
                    msg.isOwn ? 'text-blue-200' : 'text-gray-400'
                  }`}>
                    {formatChatTime(msg.timestamp)}
                  </span>
                </div>
                <p className="text-sm break-words">{msg.message}</p>
              </div>
            </div>
          ))
        )}
        <div ref={messagesEndRef} />
      </div>
      
      {/* 發送訊息 */}
      <div className="p-3 border-t border-gray-200">
        <div className="flex space-x-2">
          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && onSendMessage()}
            placeholder="輸入訊息..."
            className="flex-1 p-2 text-sm border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            maxLength={100}
          />
          <Button
            onClick={onSendMessage}
            disabled={!newMessage.trim()}
            size="sm"
            className="bg-blue-600 hover:bg-blue-700"
          >
            <Send className="w-4 h-4" />
          </Button>
        </div>
      </div>
    </div>
  );
};
