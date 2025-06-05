
import React from 'react';
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
  return (
    <div className="flex-shrink-0 flex flex-col items-center mb-4">
      <div className="grid grid-cols-5 gap-1 mb-4 max-w-xs">
        {bingoCard.numbers.map((number, index) => (
          <button
            key={index}
            onClick={() => onMarkNumber(index)}
            disabled={!drawnNumbers.includes(number) || bingoCard.marked[index]}
            className={`w-12 h-12 text-sm font-bold rounded border-2 ${
              bingoCard.marked[index]
                ? 'bg-green-500 text-white border-green-600'
                : drawnNumbers.includes(number)
                  ? 'bg-yellow-200 text-yellow-800 border-yellow-400 hover:bg-yellow-300'
                  : 'bg-gray-100 text-gray-600 border-gray-300'
            }`}
          >
            {number}
          </button>
        ))}
      </div>
      
      <div className="text-center">
        <p className="text-sm text-gray-600 mb-2">
          點擊已抽取的號碼來標記
        </p>
      </div>
    </div>
  );
};
