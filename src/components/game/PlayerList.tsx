import React from 'react';
import { RoomPlayer } from '@/types/game';
import { Separator } from '@/components/ui/separator';
import { useLanguage } from '@/contexts/LanguageContext';

interface PlayerListProps {
  players: RoomPlayer[];
  deviceName: string;
}

export const PlayerList: React.FC<PlayerListProps> = ({ players, deviceName }) => {
  const { t } = useLanguage();
  
  return (
    <>
      <div className="mb-4 p-3 bg-gray-50 rounded-lg">
        <div className="text-sm text-gray-800 mb-2">{t('room_players')}:</div>
        <div className="grid grid-cols-2 gap-2">
          {players.map((player, index) => (
            <div key={index} className={`text-xs p-2 rounded ${
              player.name === deviceName ? 'text-white' :
              player.hasWon ? 'text-white' :
              'bg-white text-gray-700'
            }`} style={{
              backgroundColor: player.name === deviceName ? '#263ee4' : 
                             player.hasWon ? '#10d76a' : undefined
            }}>
              <div className="font-medium">{player.name}</div>
              <div>{player.completedLines} {t('completed_lines_count')}</div>
            </div>
          ))}
        </div>
      </div>
      <Separator className="border-black" />
    </>
  );
};
