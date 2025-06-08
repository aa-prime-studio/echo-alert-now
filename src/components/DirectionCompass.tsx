import React from 'react';
import { Navigation } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';

interface DirectionCompassProps {
  direction: 'N' | 'NE' | 'E' | 'SE' | 'S' | 'SW' | 'W' | 'NW';
  distance: number;
  className?: string;
}

const directionAngles = {
  N: 0,
  NE: 45,
  E: 90,
  SE: 135,
  S: 180,
  SW: 225,
  W: 270,
  NW: 315
};

const directionKeys = {
  N: 'direction_n',
  NE: 'direction_ne',
  E: 'direction_e',
  SE: 'direction_se',
  S: 'direction_s',
  SW: 'direction_sw',
  W: 'direction_w',
  NW: 'direction_nw'
};

export const DirectionCompass: React.FC<DirectionCompassProps> = ({ 
  direction, 
  distance, 
  className = '' 
}) => {
  const { t } = useLanguage();
  const angle = directionAngles[direction];
  const label = t(directionKeys[direction]);
  
  const formatDistance = (dist: number) => {
    if (dist < 1000) {
      return `${dist}m`;
    } else {
      return `${(dist / 1000).toFixed(1)}km`;
    }
  };

  return (
    <div className={`flex items-center space-x-2 ${className}`}>
      <Navigation 
        className="w-4 h-4 text-gray-600" 
        style={{ transform: `rotate(${angle}deg)` }}
      />
      <div className="text-right">
        <div className="text-lg font-semibold text-gray-900">{formatDistance(distance)}</div>
        <div className="text-sm text-gray-500">{label}</div>
      </div>
    </div>
  );
};
