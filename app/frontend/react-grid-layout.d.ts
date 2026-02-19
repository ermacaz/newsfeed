declare module 'react-grid-layout' {
  import * as React from 'react';

  interface Layout {
    i: string;
    x: number;
    y: number;
    w: number;
    h: number;
  }

  interface GridLayoutProps {
    className?: string;
    layout: Layout[];
    cols?: number;
    rowHeight?: number;
    autoSize?: boolean;
    width?: number;
    draggableHandle?: string;
    onLayoutChange?: (layout: Layout[]) => void;
    children: React.ReactNode;
  }

  export default class GridLayout extends React.Component<GridLayoutProps> {}
}
