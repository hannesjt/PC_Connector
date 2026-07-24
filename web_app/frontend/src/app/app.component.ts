import { Component, inject } from "@angular/core";
import { RouterOutlet } from "@angular/router";
import { ToastService } from "./core/services/toast.service";

@Component({
  selector: "app-root",
  standalone: true,
  imports: [RouterOutlet],
  template: `
    <router-outlet></router-outlet>
    @if (toast.message(); as msg) {
      <div class="toast">{{ msg }}</div>
    }
  `,
})
export class AppComponent {
  protected toast = inject(ToastService);
}
