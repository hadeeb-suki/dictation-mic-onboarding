import type { ComponentChildren, JSX } from "preact";

function cn(...classes: Array<string | false | null | undefined>): string {
  return classes.filter(Boolean).join(" ");
}

type ButtonProps = Omit<JSX.IntrinsicElements["button"], "className"> & {
  className?: string;
};

function Button({ className, children, ...rest }: ButtonProps) {

  return (
    <button className={cn("btn", className)} {...rest}>
      {children}
    </button>
  );
}

type HeadingProps = {
  variant?: "header-m" | "header-s";
  className?: string;
  children?: ComponentChildren;
};

function Heading({ variant = "header-m", className, children }: HeadingProps) {
  if (variant === "header-s") {
    return <h2 className={cn("text-lg font-semibold", className)}>{children}</h2>;
  }

  return <h1 className={cn("text-2xl font-bold", className)}>{children}</h1>;
}

type TextProps = JSX.IntrinsicElements["p"];

function Text({ className, children, ...rest }: TextProps) {
  return (
    <p className={cn("text-base leading-relaxed", className as string)} {...rest}>
      {children}
    </p>
  );
}

export { Button, Heading, Text };
