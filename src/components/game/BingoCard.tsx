import React from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { BingoCard as BingoCardType } from '@/types/game';

interface BingoCardProps {
  bingoCard: BingoCardType;
  drawnNumbers: number[];
  onMarkNumber: (index: number) => void;
  gameWon: boolean;
}

export const BingoCard: React.FC<BingoCardProps> = ({
  bingoCard,
  drawnNumbers,
  onMarkNumber,
  gameWon
}) => {
  const { t } = useLanguage();
  
  return (
    <div className="flex-shrink-0 flex flex-col items-center mb-4">
      <div className="grid grid-cols-5 gap-1 mb-4 max-w-xs">
        {bingoCard.numbers.map((number, index) => (
          <button
            key={index}
            onClick={() => onMarkNumber(index)}
            disabled={!drawnNumbers.includes(number) || bingoCard.marked[index]}
            className="w-12 h-12 text-sm font-bold rounded border-2"
            style={{
              backgroundColor: bingoCard.marked[index] 
                ? '#10d76a'
                : drawnNumbers.includes(number)
                  ? '#263ee4'
                  : '#263ee4',
              borderColor: bingoCard.marked[index]
                ? '#10d76a'
                : drawnNumbers.includes(number)
                  ? '#263ee4'
                  : '#263ee4',
              color: bingoCard.marked[index] ? 'white' : '#ffec79',
              opacity: !drawnNumbers.includes(number) ? 0.5 : 1
            }}
          >
            {number}
          </button>
        ))}
      </div>
      
      <div className="text-center">
        <p className="text-sm text-gray-600 mb-2">
          {t('click_to_mark')}
        </p>
      </div>
    </div>
  );
};
