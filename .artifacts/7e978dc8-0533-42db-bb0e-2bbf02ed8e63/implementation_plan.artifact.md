# Implementation Plan - Performance Optimization and Pagination

The goal is to improve the app's performance and responsiveness, especially when switching tabs and displaying large lists of buyers. We will implement lazy loading and optimize list rendering using Flutter's scroll performance best practices.

## User Review Required

> [!IMPORTANT]
> The UI for long lists will now load 15 items initially and load more as the user scrolls. This significantly reduces the initial render time when switching sections.
>
> [!NOTE]
> I will replace `shrinkWrap: true` in several `ListView`s with `Sliver` based layouts or constrained `ListView`s to ensure lazy loading works correctly.

## Proposed Changes

### [Models & Providers]

#### [MODIFY] [buyer_provider.dart](file:///C:/Users/darsh/.gemini/antigravity/scratch/buyer_crm_app/lib/providers/buyer_provider.dart)
- Optimize `_rebuildCaches` to be more efficient.
- Ensure `paginatedFilteredBuyers` and `paginatedDailyWorkAreaBuyers` are used correctly to provide data in chunks.

### [UI Components]

#### [MODIFY] [daily_work_area_view.dart](file:///C:/Users/darsh/.gemini/antigravity/scratch/buyer_crm_app/lib/views/widgets/daily_work_area_view.dart)
- Replace the `SingleChildScrollView` + `ListView` structure with a `CustomScrollView` and `SliverList`.
- Implement a "Load More" trigger when the user scrolls to the bottom of the sections.
- Ensure each section (Overdue, Follow-ups, First Emails) only renders its visible items.

#### [MODIFY] [dashboard_view.dart](file:///C:/Users/darsh/.gemini/antigravity/scratch/buyer_crm_app/lib/views/dashboard_view.dart)
- Similar to `DailyWorkAreaView`, use `CustomScrollView` for the "All Importers" view.
- Remove `shrinkWrap: true` from the `ListView`s in `_buildFirstEmailQueueSection` and `_buildFollowupQueueSection`.
- Implement pagination trigger.

### [Optimizations]

- Reduce the overhead of `SelectionArea` by applying it more selectively or ensuring it doesn't wrap massive non-visible lists.
- Debounce expensive operations if necessary.

## Verification Plan

### Automated Tests
- N/A (Manual verification is more effective for UI lag/performance in this context).

### Manual Verification
- **Speed Test**: Switch between "Daily Work Area" and "All Importers" multiple times. The transition should be nearly instantaneous.
- **Scroll Test**: Scroll to the bottom of the lists. Ensure "Load More" triggers and new data appears smoothly without lag.
- **Search Test**: Type in the search box. Ensure the search results update quickly and only show the first batch initially.
- **Interaction Test**: Click buttons, checkboxes, and links. Ensure they remain responsive even with large datasets.
