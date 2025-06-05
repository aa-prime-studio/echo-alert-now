
import React from 'react';
import { Button } from '@/components/ui/button';
import { BingoRoom } from '@/types/game';

interface RoomSelectorProps {
  rooms: BingoRoom[];
  onJoinRoom: (roomId: number) => void;
}

export const RoomSelector: React.FC<RoomSelectorProps> = ({ rooms, onJoinRoom }) => {
  return (
    <div>
      <h4 className="font-semibold text-gray-900 mb-3">選擇房間</h4>
      <div className="relative h-56 flex items-center justify-center">
        {/* Room B - Right (垂直翻轉，底部對齊C) */}
        <div 
          className="absolute bottom-0 right-1/2 transform translate-x-1/2 w-40 h-40 flex items-end justify-end cursor-pointer"
          style={{
            backgroundColor: '#ff5663',
            clipPath: 'polygon(0% 0%, 100% 0%, 0% 100%)',
            transform: 'translateX(50%) scaleY(-1)'
          }}
          onClick={() => onJoinRoom(2)}
        >
          <span 
            className="font-bold text-lg absolute"
            style={{ 
              color: '#00d76a',
              bottom: '8px',
              left: '8px',
              transform: 'scaleY(-1)'
            }}
          >
            2
          </span>
        </div>
        
        {/* Room A - Bottom Left */}
        <div 
          className="absolute bottom-0 left-8 w-40 h-40 flex items-end justify-start cursor-pointer"
          style={{
            backgroundColor: '#ff5663',
            clipPath: 'polygon(0% 0%, 100% 0%, 0% 100%)'
          }}
          onClick={() => onJoinRoom(1)}
        >
          <span 
            className="font-bold text-lg absolute"
            style={{ 
              color: '#00d76a',
              bottom: '8px',
              left: '8px'
            }}
          >
            1
          </span>
        </div>
        
        {/* Room C - Bottom Right */}
        <div 
          className="absolute bottom-0 right-8 w-40 h-40 flex items-end justify-end cursor-pointer"
          style={{
            backgroundColor: '#ff5663',
            clipPath: 'polygon(0% 0%, 100% 0%, 100% 100%)'
          }}
          onClick={() => onJoinRoom(3)}
        >
          <span 
            className="font-bold text-lg absolute"
            style={{ 
              color: '#00d76a',
              bottom: '8px',
              right: '8px'
            }}
          >
            3
          </span>
        </div>
      </div>
    </div>
  );
};
