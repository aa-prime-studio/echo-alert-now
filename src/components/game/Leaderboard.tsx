import React from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { BingoScore } from '@/types/game';

interface LeaderboardProps {
  leaderboard: BingoScore[];
}

export const Leaderboard: React.FC<LeaderboardProps> = ({ leaderboard }) => {
  const { t } = useLanguage();
  
  if (leaderboard.length === 0) return null;

  return (
    <div>
      <h4 className="text-base font-semibold text-gray-900 text-left mb-3" style={{ fontSize: '1rem' }}>
        {t('daily_ranking')}
      </h4>
      <div className="space-y-2">
        {leaderboard.slice(0, 5).map((score, index) => (
          <div key={`${score.deviceName}-${score.timestamp}`} className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <span className={`w-5 h-5 rounded-full flex items-center justify-center text-xs font-bold ${
                index === 0 ? 'bg-yellow-100 text-yellow-800' :
                index === 1 ? 'bg-gray-100 text-gray-700' :
                index === 2 ? 'bg-orange-100 text-orange-700' :
                'bg-blue-50 text-blue-600'
              }`}>
                {index + 1}
              </span>
              <span className="text-gray-900" style={{ fontSize: '14.5px' }}>{score.deviceName}</span>
            </div>
            <span className="font-medium text-gray-700" style={{ fontSize: '14.5px' }}>
              {score.score} {t('completed_lines_count')}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};
