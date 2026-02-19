declare module 'react-lazy-load-image-component' {
  import * as React from 'react';

  interface LazyLoadImageProps extends React.ImgHTMLAttributes<HTMLImageElement> {
    src: string;
    alt?: string;
    style?: React.CSSProperties;
    className?: string;
    height?: string | number;
    width?: string | number;
    placeholderSrc?: string;
    threshold?: number;
    beforeLoad?: () => void;
    afterLoad?: () => void;
    onLoad?: (event: React.SyntheticEvent<HTMLImageElement>) => void;
    onError?: (event: React.SyntheticEvent<HTMLImageElement>) => void;
  }

  export const LazyLoadImage: React.FC<LazyLoadImageProps>;
}
