import { Routes } from "@angular/router";

export const routes: Routes = [
  {
    path: "",
    loadComponent: () =>
      import("./features/devices/device-list.component").then(
        (m) => m.DeviceListComponent,
      ),
  },
  {
    path: "setup",
    loadComponent: () =>
      import("./features/devices/setup.component").then(
        (m) => m.SetupComponent,
      ),
  },
  {
    path: "pc/:id",
    loadComponent: () =>
      import("./features/home/home.component").then((m) => m.HomeComponent),
  },
  {
    path: "pc/:id/input",
    loadComponent: () =>
      import("./features/input/input-control.component").then(
        (m) => m.InputControlComponent,
      ),
  },
  {
    path: "pc/:id/files",
    loadComponent: () =>
      import("./features/files/file-explorer.component").then(
        (m) => m.FileExplorerComponent,
      ),
  },
  {
    path: "pc/:id/screen",
    loadComponent: () =>
      import("./features/screen/screen-view.component").then(
        (m) => m.ScreenViewComponent,
      ),
  },
  {
    path: "pc/:id/history",
    loadComponent: () =>
      import("./features/history/history.component").then(
        (m) => m.HistoryComponent,
      ),
  },
  { path: "**", redirectTo: "" },
];
