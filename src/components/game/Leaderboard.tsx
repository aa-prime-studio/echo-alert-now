import React from 'react';
import { Trophy } from 'lucide-react';
import { BingoScore } from '@/types/game';

interface LeaderboardProps {
  leaderboard: BingoScore[];
}

export const Leaderboard: React.FC<LeaderboardProps> = ({ leaderboard }) => {
  if (leaderboard.length === 0) return null;

  return (
    <div>
      <div className="flex items-center space-x-2 mb-3">
        <Trophy className="w-4 h-4 text-yellow-600" />
        <h4 className="font-semibold text-gray-900 text-left" style={{ fontSize: '17px' }}>今日排行榜</h4>
      </div>
      <div className="space-y-2">
        {leaderboard.slice(0, 5).map((score, index) => (
          <div key={`${score.deviceName}-${score.timestamp}`} className="flex items-center justify-between text-sm">
            <div className="flex items-center space-x-2">
              <span className={`w-5 h-5 rounded-full flex items-center justify-center text-xs font-bold ${
                index === 0 ? 'bg-yellow-100 text-yellow-800' :
                index === 1 ? 'bg-gray-100 text-gray-700' :
                index === 2 ? 'bg-orange-100 text-orange-700' :
                'bg-blue-50 text-blue-600'
              }`}>
                {index + 1}
              </span>
              <span className="text-gray-900">{score.deviceName}</span>
            </div>
            <span className="font-medium text-gray-700">{score.score}線</span>
          </div>
        ))}
      </div>
    </div>
  );
};
