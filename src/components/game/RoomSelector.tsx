
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
        {/* Room B - Top Triangle */}
        <div 
          className="absolute top-0 left-1/2 transform -translate-x-1/2 w-48 h-40 flex items-center justify-center cursor-pointer"
          style={{
            backgroundColor: '#ff5663',
            clipPath: 'polygon(50% 0%, 0% 100%, 100% 100%)'
          }}
          onClick={() => onJoinRoom(2)}
        >
          <span className="font-bold text-lg mt-6" style={{ color: '#00d76a' }}>room B</span>
        </div>
        
        {/* Room A - Bottom Left Triangle */}
        <div 
          className="absolute bottom-0 left-8 w-48 h-40 flex items-center justify-center cursor-pointer"
          style={{
            backgroundColor: '#ff5663',
            clipPath: 'polygon(0% 100%, 100% 100%, 0% 0%)'
          }}
          onClick={() => onJoinRoom(1)}
        >
          <span className="font-bold text-lg mb-6 mr-8" style={{ color: '#00d76a' }}>room A</span>
        </div>
        
        {/* Room C - Bottom Right Triangle */}
        <div 
          className="absolute bottom-0 right-8 w-48 h-40 flex items-center justify-center cursor-pointer"
          style={{
            backgroundColor: '#ff5663',
            clipPath: 'polygon(100% 0%, 100% 100%, 0% 100%)'
          }}
          onClick={() => onJoinRoom(3)}
        >
          <span className="font-bold text-lg mb-6 ml-8" style={{ color: '#00d76a' }}>room C</span>
        </div>
      </div>
    </div>
  );
};
