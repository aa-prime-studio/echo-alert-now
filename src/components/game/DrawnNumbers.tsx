
import React from 'react';

interface DrawnNumbersProps {
  drawnNumbers: number[];
}

export const DrawnNumbers: React.FC<DrawnNumbersProps> = ({ drawnNumbers }) => {
  return (
    <div className="mb-4 p-3 rounded-lg">
      <div className="text-sm text-gray-800 mb-2">已抽取號碼:</div>
      <div className="flex flex-wrap gap-1">
        {drawnNumbers.slice(-10).map((num, index) => (
          <span key={index} className={`px-2 py-1 rounded text-xs font-bold ${
            index === drawnNumbers.slice(-10).length - 1 
              ? 'text-white' 
              : ''
          }`} style={{
            backgroundColor: index === drawnNumbers.slice(-10).length - 1 ? '#10d76a' : '#263ee4',
            color: index === drawnNumbers.slice(-10).length - 1 ? 'white' : '#ffec79'
          }}>
            {num}
          </span>
        ))}
      </div>
      {drawnNumbers.length > 0 && (
        <div className="text-xs text-gray-600 mt-1">
          最新號碼: {drawnNumbers[drawnNumbers.length - 1]}
        </div>
      )}
    </div>
  );
};
