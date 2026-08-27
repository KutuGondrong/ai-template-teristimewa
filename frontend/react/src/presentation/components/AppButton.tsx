import type { ButtonHTMLAttributes, ReactNode } from "react";

const variants = {
  primary: "btn-primary",
  outline: "btn-outline",
  ghost: "btn-ghost",
  icon: "btn-icon",
} as const;

export function AppButton({
  variant = "primary",
  className = "",
  children,
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: keyof typeof variants;
  children: ReactNode;
}) {
  return (
    <button className={`btn ${variants[variant]} ${className}`} {...props}>
      {children}
    </button>
  );
}
