
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
      <div className="relative h-48">
        {/* Room A - Bottom Left Triangle */}
        <div 
          className="absolute bottom-0 left-0 w-40 h-32 bg-red-400 flex items-center justify-center cursor-pointer"
          style={{
            clipPath: 'polygon(0% 100%, 100% 100%, 0% 0%)'
          }}
          onClick={() => onJoinRoom(1)}
        >
          <span className="text-green-600 font-bold text-lg">room A</span>
        </div>
        
        {/* Room B - Top Triangle */}
        <div 
          className="absolute top-0 left-1/2 transform -translate-x-1/2 w-40 h-32 bg-red-400 flex items-center justify-center cursor-pointer"
          style={{
            clipPath: 'polygon(50% 0%, 0% 100%, 100% 100%)'
          }}
          onClick={() => onJoinRoom(2)}
        >
          <span className="text-green-600 font-bold text-lg">room B</span>
        </div>
        
        {/* Room C - Bottom Right Triangle */}
        <div 
          className="absolute bottom-0 right-0 w-40 h-32 bg-red-400 flex items-center justify-center cursor-pointer"
          style={{
            clipPath: 'polygon(100% 0%, 100% 100%, 0% 100%)'
          }}
          onClick={() => onJoinRoom(3)}
        >
          <span className="text-green-600 font-bold text-lg">room C</span>
        </div>
      </div>
    </div>
  );
};
