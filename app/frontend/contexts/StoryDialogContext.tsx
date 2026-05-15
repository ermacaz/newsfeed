import React, { createContext, useContext, useMemo, ReactNode } from "react";
import { Story } from "../types";

// State and actions live in separate contexts so components that only need
// the setter (e.g. NewsSource, NewsStory) don't re-render when the dialog
// opens or closes. This is what makes React.memo on the list components
// actually skip work — a single-context value would still change identity
// every time showStoryDialog updates.

const StoryDialogStateContext = createContext<Story | null>(null);

interface StoryDialogActions {
  setShowStoryDialog: (story: Story | null) => void;
}
const StoryDialogActionsContext = createContext<StoryDialogActions>({
  setShowStoryDialog: () => {},
});

interface ProviderProps {
  showStoryDialog: Story | null;
  setShowStoryDialog: (story: Story | null) => void;
  children: ReactNode;
}

export function StoryDialogProvider({
  showStoryDialog,
  setShowStoryDialog,
  children,
}: ProviderProps): React.ReactElement {
  // setShowStoryDialog from useState has stable identity across renders, so
  // this object reference is stable too — consumers of actions never re-render.
  const actions = useMemo<StoryDialogActions>(
    () => ({ setShowStoryDialog }),
    [setShowStoryDialog]
  );
  return (
    <StoryDialogActionsContext.Provider value={actions}>
      <StoryDialogStateContext.Provider value={showStoryDialog}>
        {children}
      </StoryDialogStateContext.Provider>
    </StoryDialogActionsContext.Provider>
  );
}

export const useStoryDialogState = (): Story | null =>
  useContext(StoryDialogStateContext);

export const useStoryDialogActions = (): StoryDialogActions =>
  useContext(StoryDialogActionsContext);
