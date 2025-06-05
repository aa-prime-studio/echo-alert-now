
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
      <h4 className="text-sm font-medium text-gray-900 mb-3">選擇房間</h4>
      <div className="grid grid-cols-1 gap-3">
        {rooms.map((room) => (
          <Button
            key={room.id}
            onClick={() => onJoinRoom(room.id)}
            className="h-16 bg-blue-600 hover:bg-blue-700 text-white flex flex-col items-center justify-center"
          >
            <span className="text-lg font-bold">{room.name}</span>
          </Button>
        ))}
      </div>
    </div>
  );
};
